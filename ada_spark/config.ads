with Types; use Types;

package Config is

   --  Constants used to configure the drone firmware

   --  Crazyflie 2.0 has an SMTM32F4 board
   STM32F4XX : constant Boolean := True;
   QUAD_FORMATION_X : constant Boolean := True;
   CPU_CLOCK_HZ : constant T_Uint32 := 168000000;
   TICK_RATE_HZ : constant T_Uint16 := 1000;
   TICK_RATE_MS : constant T_Uint16 := 1000 / TICK_RATE_HZ;

   --  Two implemented algorithms for quaternions
   type Quaternion_Algorithm is (MAHONY, MADGWICK);
   SENSOR_FUSION_ALGORITHM : constant Quaternion_Algorithm := MAHONY;

   --  Link layers implemented to communicate via the CRTP protocol
   type Link_Layer is (RADIO_LINK, USB_LINK, ESKY_LINK);
   LINK_LAYER_TYPE : constant Link_Layer := RADIO_LINK;

   PORT_MAX_DELAY : constant T_Uint16 := T_Uint16'Last;

   PORT_MAX_DELAY_TIME : constant Integer :=
                           Integer (PORT_MAX_DELAY / TICK_RATE_MS);

   --  Radio configuration
   RADIO_CHANNEL       : constant := 80;
   RADIO_DATARATE      : constant := 0;

end Config;
