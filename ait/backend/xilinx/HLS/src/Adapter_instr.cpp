/*------------------------------------------------------------------------*/
/*    (C) Copyright 2017-2022 Barcelona Supercomputing Center             */
/*                            Centro Nacional de Supercomputacion         */
/*                                                                        */
/*    This file is part of OmpSs@FPGA toolchain.                          */
/*                                                                        */
/*    This code is free software; you can redistribute it and/or modify   */
/*    it under the terms of the GNU Lesser General Public License as      */
/*    published by the Free Software Foundation; either version 3 of      */
/*    the License, or (at your option) any later version.                 */
/*                                                                        */
/*    OmpSs@FPGA toolchain is distributed in the hope that it will be     */
/*    useful, but WITHOUT ANY WARRANTY; without even the implied          */
/*    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    */
/*    See the GNU Lesser General Public License for more details.         */
/*                                                                        */
/*    You should have received a copy of the GNU Lesser General Public    */
/*    License along with this code. If not, see <www.gnu.org/licenses/>.  */
/*------------------------------------------------------------------------*/

#include <cstring>
#include <hls_stream.h>
#include <ap_axi_sdata.h>

//Default instrumentation events codes
#define EV_DEVCOPYIN            78
#define EV_DEVCOPYOUT           79
#define EV_DEVEXEC              80
#define EV_INSTEVLOST           82

typedef ap_uint<105> portData_t;
typedef unsigned long long int counter_t;
typedef struct event_t {
	unsigned long long int value;
	unsigned long long int timestamp;
	unsigned long long int typeAndId;
} event_t;
typedef enum eventType_t {
	EVENT_TYPE_BURST_OPEN = 0,
	EVENT_TYPE_BURST_CLOSE = 1,
	EVENT_TYPE_POINT = 2,
	EVENT_TYPE_INVALID = 0XFFFFFFFF
} eventType_t;

unsigned long long int get_typeAndId(volatile unsigned long long int * instr_buffer, unsigned long long int offset, unsigned short int slot) {
	#pragma HLS INTERFACE m_axi port=instr_buffer
	return *((unsigned long long int*)(instr_buffer + ((offset + slot*sizeof(event_t) + offsetof(event_t, typeAndId))/sizeof(unsigned long long int))));
}

void Adapter_instr_wrapper(
	volatile counter_t hwcounter,
	volatile unsigned long long int * instr_buffer,
	portData_t& in)
{
	#pragma HLS INTERFACE ap_ctrl_none port=return
	#pragma HLS INTERFACE m_axi port=instr_buffer
	#pragma HLS INTERFACE ap_hs port=in

	static unsigned short int instr_slots, instr_currentSlot, instr_numOverflow, instr_avSlots;
	static unsigned long long int instr_buffer_offset;
	static ap_uint<1> __reset = 0;
	#pragma HLS RESET variable=__reset

	if (__reset == 0) {
		__reset = 1;
		instr_slots = 0;
		instr_avSlots = 0;
		instr_currentSlot = 0;
		instr_numOverflow = 0;
		instr_buffer_offset = 0;
	} else {
		// Structure of in data:
		// If bit 104 is 0 -> the data represents an instrumentation setup where:
		//   - data[63,  0] is the instrumentation buffer offset
		//   - data[79, 64] is the number of slots pointer by the instrumentation offset
		// If bit 104 is 1 -> the data represents an instrumentation event where:
		//   - data[63,  0] is value field of the instrumentation event
		//   - data[103,64] is typeAndId field of the instrumentation event
		portData_t data = in;

		if (data.bit(104) == 0) {
			instr_slots = (unsigned short int)data.range(79,64);
			instr_avSlots = instr_slots;
			instr_currentSlot = 0;
			instr_numOverflow = 0;
			instr_buffer_offset = (unsigned long long int)data.range(63,0);
		} else if (instr_slots > 0) {
			const counter_t timestamp = hwcounter;
			if (instr_avSlots == 1) {
				// There is only one slot (reserved for overflow events) -> check if previous have been read
				unsigned short int i = instr_currentSlot + 1  == instr_slots ? 0 : instr_currentSlot + 1;
				unsigned long long int typeAndId = get_typeAndId(instr_buffer, instr_buffer_offset, i);
				while (((typeAndId >> 32) == EVENT_TYPE_INVALID) && (instr_avSlots < instr_slots)) {
					instr_avSlots++;
					i = i + 1 == instr_slots ? 0 : i + 1;
					typeAndId = get_typeAndId(instr_buffer, instr_buffer_offset, i);
				}
				if (instr_avSlots > 1 && instr_numOverflow > 0) {
					// The last slot was used for overflow event -> write to the next slot
					instr_numOverflow = 0;
					instr_currentSlot = instr_currentSlot + 1 == instr_slots ? 0 : instr_currentSlot + 1;
				}
			}
			const unsigned long long int slot_offset = (instr_buffer_offset + instr_currentSlot*sizeof(event_t))/sizeof(unsigned long long int);
			const unsigned short int can_write_event = instr_avSlots > 1;
			instr_currentSlot = instr_currentSlot + can_write_event == instr_slots ? 0 : instr_currentSlot + can_write_event;
			instr_avSlots -= can_write_event;
			instr_numOverflow += !can_write_event;

			const unsigned long long int typeAndId_ev = (unsigned long long int)data.range(103, 64);
			const unsigned long long int typeAndId_of = (((unsigned long long int)EVENT_TYPE_POINT)<<32) | EV_INSTEVLOST;
			const unsigned long long int value_ev = (unsigned long long int)data.range(63, 0);
			const unsigned long long int value_of = instr_numOverflow;

			event_t fpga_event;
			fpga_event.timestamp = timestamp;
			fpga_event.typeAndId = can_write_event ? typeAndId_ev : typeAndId_of;
			fpga_event.value = can_write_event ? value_ev : value_of;
			memcpy((void *)(instr_buffer + slot_offset), &fpga_event, sizeof(event_t));
		}

	}
}
