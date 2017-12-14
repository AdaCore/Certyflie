------------------------------------------------------------------------------
--                              Certyflie                                   --
--                                                                          --
--                     Copyright (C) 2015-2017, AdaCore                     --
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

with Ada.Unchecked_Conversion;

with Link_Interface;      use Link_Interface;
pragma Elaborate (Link_Interface);

with LEDS;                use LEDS;

package body CRTP
with Refined_State => (CRTP_State => (Dropped_Packets,
                                      Is_Connected))
is

   -----------------------
   -- CRTP_Tx_Task_Type --
   -----------------------

   task body CRTP_Tx_Task_Type is
      Packet : CRTP_Packet;
      Has_Succeed : Boolean;
      pragma Unreferenced (Has_Succeed);
   begin
      loop
         Tx_Queue.Await_Item_To_Dequeue
           (Packet);

         Has_Succeed := Link_Send_Packet (Packet);
      end loop;
   end CRTP_Tx_Task_Type;

   -----------------------
   -- CRTP_Rx_Task_Type --
   -----------------------

   task body CRTP_Rx_Task_Type is
      Packet : CRTP_Packet;
      Has_Succeed : Boolean;
   begin
      loop
         Link_Receive_Packet_Blocking (Packet);

         if Callbacks (Packet.Port) /= null then
            Callbacks (Packet.Port) (Packet);
         else
            Port_Queues (Packet.Port).Enqueue_Item (Packet, Has_Succeed);
         end if;
      end loop;
   end CRTP_Rx_Task_Type;

   ------------------------
   -- CRTP_Create_Packet --
   ------------------------

   function CRTP_Create_Packet
     (Port : CRTP_Port;
      Channel : CRTP_Channel) return CRTP_Packet_Handler is
      Packet : CRTP_Packet;
      Handler : CRTP_Packet_Handler;
   begin
      Packet.Size := 0;
      Packet.Reserved := 0;
      Packet.Port := Port;
      Packet.Channel := Channel;

      Handler.Index := 1;
      Handler.Packet := Packet;

      return Handler;
   end CRTP_Create_Packet;

   ----------------------------------
   -- CRTP_Get_Handler_From_Packet --
   ----------------------------------

   function CRTP_Get_Handler_From_Packet
     (Packet : CRTP_Packet) return CRTP_Packet_Handler
   is
      Handler : CRTP_Packet_Handler;
   begin
      Handler.Packet := Packet;
      Handler.Index := Integer (Packet.Size);

      return Handler;
   end CRTP_Get_Handler_From_Packet;

   ----------------------------------
   -- CRTP_Get_Packet_From_Handler --
   ----------------------------------

   function CRTP_Get_Packet_From_Handler
     (Handler : CRTP_Packet_Handler) return CRTP_Packet is
   begin
      return Handler.Packet;
   end CRTP_Get_Packet_From_Handler;

   -------------------
   -- CRTP_Get_Data --
   -------------------

   procedure CRTP_Get_Data
     (Handler     : CRTP_Packet_Handler;
      Index       : Integer;
      Data        : in out T_Data;
      Has_Succeed : out Boolean)
   is
      Data_Size : constant Natural := T_Data'Size / 8;
      subtype Byte_Array_Data is T_Uint8_Array (1 .. Data_Size);

      ------------------------
      -- Byte_Array_To_Data --
      ------------------------

      function Byte_Array_To_Data is new Ada.Unchecked_Conversion
        (Byte_Array_Data, T_Data);
   begin
      if Index in Handler.Packet.Data_1'First ..
        Handler.Packet.Data_1'Last - Data_Size - 1
      then
         Data := Byte_Array_To_Data
           (Handler.Packet.Data_1 (Index .. Index + Data_Size - 1));
         Has_Succeed := True;
      else
         Has_Succeed := False;
      end if;
   end CRTP_Get_Data;

   ----------------------
   -- CRTP_Append_Data --
   ----------------------

   procedure CRTP_Append_Data
     (Handler : in out CRTP_Packet_Handler;
      Data           : T_Data;
      Has_Succeed     : out Boolean)
   is
      Data_Size : constant Natural := (T_Data'Size + 7) / 8;

      subtype Byte_Array_Data is T_Uint8_Array (1 .. Data_Size);

      ------------------------
      -- Data_To_Byte_Array --
      ------------------------

      function Data_To_Byte_Array is new Ada.Unchecked_Conversion
        (T_Data, Byte_Array_Data);
   begin
      if Handler.Index + Data_Size - 1 <= Handler.Packet.Data_1'Last then
         Handler.Packet.Data_1
           (Handler.Index .. Handler.Index + Data_Size - 1) :=
           Data_To_Byte_Array (Data);

         Handler.Packet.Size := Handler.Packet.Size + T_Uint8 (Data_Size);
         Handler.Index := Handler.Index + Data_Size;
         Has_Succeed := True;
      else
         Has_Succeed := False;
      end if;
   end CRTP_Append_Data;

   ------------------------
   -- CRTP_Reset_Handler --
   ------------------------

   procedure CRTP_Reset_Handler (Handler : in out CRTP_Packet_Handler) is
   begin
      Handler.Index := 1;
      Handler.Packet.Size := 0;
      Handler.Packet.Data_1 := (others => 0);
   end CRTP_Reset_Handler;

   --------------------------
   -- CRTP_Get_Packet_Size --
   --------------------------

   function CRTP_Get_Packet_Size
     (Handler : CRTP_Packet_Handler) return T_Uint8 is
   begin
      return Handler.Packet.Size;
   end CRTP_Get_Packet_Size;

   ----------------------------------
   -- CRTP_Receive_Packet_Blocking --
   ----------------------------------

   procedure CRTP_Receive_Packet_Blocking
     (Packet           : out CRTP_Packet;
      Port_ID          : CRTP_Port) is
   begin
      Port_Queues (Port_ID).Await_Item_To_Dequeue
        (Packet);
   end CRTP_Receive_Packet_Blocking;

   ----------------------
   -- CRTP_Send_Packet --
   ----------------------

   procedure CRTP_Send_Packet
     (Packet : CRTP_Packet;
      Has_Succeed : out Boolean;
      Time_To_Wait : Time_Span := Milliseconds (0))
   is
      pragma Unreferenced (Time_To_Wait);
   begin
      Tx_Queue.Enqueue_Item (Packet, Has_Succeed);
   end CRTP_Send_Packet;

   ----------------------------
   -- CRTP_Register_Callback --
   ----------------------------

   procedure CRTP_Register_Callback
     (Port_ID  : CRTP_Port;
      Callback : CRTP_Callback) is
   begin
      Callbacks (Port_ID) := Callback;
   end CRTP_Register_Callback;

   ------------------------------
   -- CRTP_Unregister_Callback --
   ------------------------------

   procedure CRTP_Unregister_Callback (Port_ID : CRTP_Port) is
   begin
      Callbacks (Port_ID) := null;
   end CRTP_Unregister_Callback;

   ----------------
   -- CRTP_Reset --
   ----------------

   procedure CRTP_Reset is
   begin
      Tx_Queue.Reset_Queue;
      --  TODO: reset the link queues too.
   end CRTP_Reset;

   ---------------------------
   -- CRTP_Set_Is_Connected --
   ---------------------------

   procedure CRTP_Set_Is_Connected (Value : Boolean) is
   begin
      Is_Connected := Value;
      LEDS.Set_Link_State ((if Value then Connected else Not_Connected));
   end CRTP_Set_Is_Connected;

   -----------------------
   -- CRTP_Is_Connected --
   -----------------------

   function CRTP_Is_Connected return Boolean is
   begin
      --  This is what crazyflie-firmware/src/modules/src/crtp.c does
      return True;
      --  return Is_Connected;
   end CRTP_Is_Connected;

end CRTP;
