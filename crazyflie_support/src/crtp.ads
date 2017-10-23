------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                     Copyright (C) 2015-2016, AdaCore                     --
--                                                                          --
--  This library is free software;  you can redistribute it and/or modify   --
--  it under terms of the  GNU General Public License  as published by the  --
--  Free Software  Foundation;  either version 3,  or (at your  option) any --
--  later version. This library is distributed in the hope that it will be  --
--  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                    --
--                                                                          --
--  As a special exception under Section 7 of GPL version 3, you are        --
--  granted additional permissions described in the GCC Runtime Library     --
--  Exception, version 3.1, as published by the Free Software Foundation.   --
--                                                                          --
--  You should have received a copy of the GNU General Public License and   --
--  a copy of the GCC Runtime Library Exception along with this program;    --
--  see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see   --
--  <http://www.gnu.org/licenses/>.                                         --
--                                                                          --
--  As a special exception, if other files instantiate generics from this   --
--  unit, or you link this unit with other files to produce an executable,  --
--  this  unit  does not  by itself cause  the resulting executable to be   --
--  covered by the GNU General Public License. This exception does not      --
--  however invalidate any other reasons why the executable file  might be  --
--  covered by the  GNU Public License.                                     --
------------------------------------------------------------------------------

with System;
with Ada.Real_Time;      use Ada.Real_Time;

with Generic_Queue;
with Types;              use Types;

package CRTP
  with Abstract_State => CRTP_State
is

   --  Constants

   CRTP_MAX_DATA_SIZE : constant := 30;
   CRTP_TX_QUEUE_SIZE : constant := 60;
   CRTP_RX_QUEUE_SIZE : constant := 2;
   CRTP_NBR_OF_PORTS  : constant := 16;

   --  Types

   --  Type used for representing a CRTP channel, which can be seen
   --  as a sub-set for a specific port.
   type CRTP_Channel is new T_Uint8 range 0 .. 3;
   for CRTP_Channel'Size use 2;

   --  Enumeration type for CRTP ports. Each port corresponds to
   --  a specific modules.
   type CRTP_Port is (CRTP_PORT_CONSOLE,
                      CRTP_PORT_PARAM,
                      CRTP_PORT_COMMANDER,
                      CRTP_PORT_MEM,
                      CRTP_PORT_LOG,
                      CRTP_PORT_PLATFORM,
                      CRTP_PORT_LINK);
   for CRTP_Port use (CRTP_PORT_CONSOLE   => 16#00#,
                      CRTP_PORT_PARAM     => 16#02#,
                      CRTP_PORT_COMMANDER => 16#03#,
                      CRTP_PORT_MEM       => 16#04#,
                      CRTP_PORT_LOG       => 16#05#,
                      CRTP_PORT_PLATFORM  => 16#0D#,
                      CRTP_PORT_LINK      => 16#0F#);
   for CRTP_Port'Size use 4;

   --  Type for representing the two reserved bits in a CRTP packet.
   --  These bits are used for the transport layer.
   type CRTP_Reserved is new T_Uint8 range 0 .. 3;
   for CRTP_Reserved'Size use 2;

   --  Type for CRTP packet data.
   subtype CRTP_Data is T_Uint8_Array (1 .. CRTP_MAX_DATA_SIZE);

   --  Type used to represenet a raw CRTP Packet (Header + Data).
   type CRTP_Raw is array (1 .. CRTP_MAX_DATA_SIZE + 1) of T_Uint8;

   --  Type listing the different representations for the union type
   --  CRTP Packet.
   type CRTP_Packet_Representation is (DETAILED, HEADER_DATA, RAW);

   --  Type for CRTP packets.
   type CRTP_Packet (Repr : CRTP_Packet_Representation := DETAILED) is record
      Size     : T_Uint8;

      case Repr is
         when DETAILED =>
            Channel    : CRTP_Channel;
            Reserved   : CRTP_Reserved;
            Port       : CRTP_Port;
            Data_1     : CRTP_Data;
         when HEADER_DATA =>
            Header     : T_Uint8;
            Data_2     : CRTP_Data;
         when RAW =>
            Raw        : CRTP_Raw;
      end case;
   end record;

   pragma Unchecked_Union (CRTP_Packet);
   for CRTP_Packet'Size use 256;
   pragma Pack (CRTP_Packet);

   --  Type used to easily manipulate CRTP packet.
   type CRTP_Packet_Handler is private;

   --  Procedures and functions

   --  Create a CRTP Packet handler to append/get data.
   function CRTP_Create_Packet
     (Port    : CRTP_Port;
      Channel : CRTP_Channel) return CRTP_Packet_Handler;

   --  Return an handler to easily manipulate the CRTP packet.
   function CRTP_Get_Handler_From_Packet
     (Packet : CRTP_Packet) return CRTP_Packet_Handler;

   --  Return the CRTP Packet contained in the CRTP Packet handler.
   function CRTP_Get_Packet_From_Handler
     (Handler : CRTP_Packet_Handler) return CRTP_Packet;

   --  Append data to the CRTP Packet.
   generic
      type T_Data is private;
   procedure CRTP_Append_Data
     (Handler        : in out CRTP_Packet_Handler;
      Data           : T_Data;
      Has_Succeed    : out Boolean);

   --  Get data at a specified index of the CRTP Packet data field.
   generic
      type T_Data is private;
   procedure CRTP_Get_Data
     (Handler     : CRTP_Packet_Handler;
      Index       : Integer;
      Data        : in out T_Data;
      Has_Succeed : out Boolean);

   --  Function pointer type for callbacks.
   type CRTP_Callback is access procedure (Packet : CRTP_Packet);

   --  Reset the index, the size and the data contained in the handler.
   procedure CRTP_Reset_Handler (Handler : in out CRTP_Packet_Handler);

   --  Get the size of the CRTP packet contained in the handler.
   function CRTP_Get_Packet_Size
     (Handler : CRTP_Packet_Handler) return T_Uint8;

   --  Receive a packet from the port queue, putting the task calling it
   --  in sleep mode while a packet has not been received
   procedure CRTP_Receive_Packet_Blocking
     (Packet           : out CRTP_Packet;
      Port_ID          : CRTP_Port);

   --  Send a packet, with a given Timeout
   procedure CRTP_Send_Packet
     (Packet : CRTP_Packet;
      Has_Succeed : out Boolean;
      Time_To_Wait : Time_Span := Milliseconds (0));

   --  Register a callback to be called when a packet is received in
   --  the port queue
   procedure CRTP_Register_Callback
     (Port_ID  : CRTP_Port;
      Callback : CRTP_Callback);

   --  Unregister the callback for this port.
   procedure CRTP_Unregister_Callback (Port_ID : CRTP_Port);

   --  Reset the CRTP module by flushing the Tx Queue.
   procedure CRTP_Reset;

   --  Used by the Commander module to state if we are still connected or not.
   procedure CRTP_Set_Is_Connected (Value : Boolean);

   --  Used to know if we are still connected.
   function CRTP_Is_Connected return Boolean;

   --  Task in charge of transmitting the messages in the Tx Queue
   --  to the link layer.
   task type CRTP_Tx_Task_Type (Prio : System.Priority) is
      pragma Priority (Prio);
   end CRTP_Tx_Task_Type;

   --  Task in charge of dequeuing the messages in the Rx_queue
   --  to put them in the Port_Queues.
   task type CRTP_Rx_Task_Type (Prio : System.Priority) is
      pragma Priority (Prio);
   end CRTP_Rx_Task_Type;

private
   package CRTP_Queue is new Generic_Queue (CRTP_Packet);

   --  Types
   type CRTP_Packet_Handler is record
      Packet : CRTP_Packet;
      Index  : Positive;
   end record;

   --  Tasks and protected objects

   pragma Warnings (Off,  "violate restriction No_Implicit_Heap_Allocation");
   --  Protected object queue for transmission.
   Tx_Queue : CRTP_Queue.Protected_Queue
     (System.Interrupt_Priority'Last, CRTP_TX_QUEUE_SIZE);

   --  Protected object queue for reception.
   Rx_Queue : CRTP_Queue.Protected_Queue
     (System.Interrupt_Priority'Last, CRTP_RX_QUEUE_SIZE);
   pragma Warnings (On,  "violate restriction No_Implicit_Heap_Allocation");

   --  Array of protected object queues, one for each task.
   Port_Queues : array (CRTP_Port) of CRTP_Queue.Protected_Queue
     (System.Interrupt_Priority'Last, 1);

   --  Array of callbacks when a packet is received.
   Callbacks : array (CRTP_Port) of CRTP_Callback := (others => null);

   --  Global variables

   --  Number of dropped packets.
   Dropped_Packets : Natural := 0
     with
       Part_Of => CRTP_State;

   --  Used to know if we are still connected or not.
   Is_Connected    : Boolean := False
     with
       Part_Of => CRTP_State;

end CRTP;
