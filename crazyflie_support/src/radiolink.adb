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

with Crazyflie_Config;                   use Crazyflie_Config;

with LEDS;

package body Radiolink is

   Red_L   : LEDS.Flasher (LEDS.LED_Red_L'Access);
   --  Indicate we've transmitted a packet.

   Green_L   : LEDS.Flasher (LEDS.LED_Green_L'Access);
   --  Indicate we've received a packet.

   --------------------
   -- Radiolink_Init --
   --------------------

   procedure Radiolink_Init is
   begin
      if Is_Init then
         return;
      end if;

      Syslink_Init;

      Radiolink_Set_Channel (RADIO_CHANNEL);
      Radiolink_Set_Data_Rate (RADIO_DATARATE);
      Radiolink_Set_Address (RADIO_ADDRESS);

      Is_Init := True;
   end Radiolink_Init;

   -----------------------------
   -- Radiolink_Set_Data_Rate --
   -----------------------------

   procedure Radiolink_Set_Data_Rate (Data_Rate : T_Uint8)
   is
      Sl_Packet : Syslink_Packet;
   begin
      Sl_Packet.Slp_Type := SYSLINK_RADIO_DATARATE;
      Sl_Packet.Length := 1;
      Sl_Packet.Data (1) := Data_Rate;
      Syslink_Send_Packet (Sl_Packet);
   end Radiolink_Set_Data_Rate;

   ---------------------------
   -- Radiolink_Set_Channel --
   ---------------------------

   procedure Radiolink_Set_Channel (Channel : T_Uint8)
   is
      Sl_Packet : Syslink_Packet;
   begin
      Sl_Packet.Slp_Type := SYSLINK_RADIO_CHANNEL;
      Sl_Packet.Length := 1;
      Sl_Packet.Data (1) := Channel;
      Syslink_Send_Packet (Sl_Packet);
   end Radiolink_Set_Channel;

   ---------------------------
   -- Radiolink_Set_Address --
   ---------------------------

   procedure Radiolink_Set_Address (Address : T_Uint64)
   is
      Sl_Packet : Syslink_Packet;
      subtype As_Bytes is T_Uint8_Array (1 .. 8);
      function Convert is new Ada.Unchecked_Conversion (T_Uint64, As_Bytes);
      Address_As_Bytes : constant As_Bytes := Convert (Address);
   begin
      Sl_Packet.Slp_Type := SYSLINK_RADIO_ADDRESS;
      Sl_Packet.Length := 5;
      Sl_Packet.Data (1 .. 5) := Address_As_Bytes (1 .. 5);
      Syslink_Send_Packet (Sl_Packet);
   end Radiolink_Set_Address;

   ---------------------------------------
   -- Radiolink_Receive_Packet_Blocking --
   ---------------------------------------

   procedure Radiolink_Receive_Packet_Blocking (Packet : out CRTP_Packet) is
   begin
      Rx_Queue.Await_Item_To_Dequeue (Packet);
   end Radiolink_Receive_Packet_Blocking;

   ---------------------------
   -- Radiolink_Send_Packet --
   ---------------------------

   function Radiolink_Send_Packet (Packet : CRTP_Packet) return Boolean
   is
      Sl_Packet : Syslink_Packet;
      Has_Succeed : Boolean;

      ------------------------------
      -- CRTP_Raw_To_Syslink_Data --
      ------------------------------

      function CRTP_Raw_To_Syslink_Data is new Ada.Unchecked_Conversion
        (CRTP_Raw, Syslink_Data);
   begin
      Sl_Packet.Length := Packet.Size + 1;
      Sl_Packet.Slp_Type := SYSLINK_RADIO_RAW;
      Sl_Packet.Data := CRTP_Raw_To_Syslink_Data (Packet.Raw);

      --  Try to enqueue the Syslink packet
      Tx_Queue.Enqueue_Item (Sl_Packet, Has_Succeed);

      return Has_Succeed;
   end Radiolink_Send_Packet;

   --------------------------------
   -- Radiolink_Syslink_Dispatch --
   --------------------------------

   procedure Radiolink_Syslink_Dispatch (Rx_Sl_Packet : Syslink_Packet)
   is
      Tx_Sl_Packet   : Syslink_Packet;
      Rx_CRTP_Packet : CRTP_Packet;
      Has_Succeed    : Boolean;
   begin
      if Rx_Sl_Packet.Slp_Type = SYSLINK_RADIO_RAW then
         Rx_CRTP_Packet.Size := Rx_Sl_Packet.Length - 1;
         Rx_CRTP_Packet.Header := Rx_Sl_Packet.Data (1);
         Rx_CRTP_Packet.Data_2 :=
           CRTP_Data (Rx_Sl_Packet.Data (2 .. Rx_Sl_Packet.Data'Length));

         --  Enqueue the received packet
         Rx_Queue.Enqueue_Item (Rx_CRTP_Packet, Has_Succeed);
         if Has_Succeed then
            Green_L.Set;
         end if;

         --  If a radio packet is received, one can be sent
         Tx_Queue.Dequeue_Item (Tx_Sl_Packet, Has_Succeed);

         if Has_Succeed then
            Red_L.Set;
            Syslink_Send_Packet (Tx_Sl_Packet);
         end if;
      elsif Rx_Sl_Packet.Slp_Type = SYSLINK_RADIO_RSSI then
         --  Extract RSSI sample sent from Radio
         RSSI := Rx_Sl_Packet.Data (1);
      end if;
   end Radiolink_Syslink_Dispatch;

end Radiolink;
