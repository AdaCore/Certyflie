package Pid_Parameters is

   --  Constants
   PID_ROLL_RATE_KP                : constant := 70.0;
   PID_ROLL_RATE_KI                : constant := 0.0;
   PID_ROLL_RATE_KD                : constant := 0.0;
   PID_ROLL_RATE_INTEGRATION_LIMIT : constant := 100.0;

   PID_PITCH_RATE_KP                : constant := 70.0;
   PID_PITCH_RATE_KI                : constant := 0.0;
   PID_PITCH_RATE_KD                : constant := 0.0;
   PID_PITCH_RATE_INTEGRATION_LIMIT : constant := 100.0;

   PID_YAW_RATE_KP                : constant := 70.0;
   PID_YAW_RATE_KI                : constant := 50.0;
   PID_YAW_RATE_KD                : constant := 0.0;
   PID_YAW_RATE_INTEGRATION_LIMIT : constant := 500.0;

   PID_ROLL_KP                : constant := 3.5;
   PID_ROLL_KI                : constant := 2.0;
   PID_ROLL_KD                : constant := 0.0;
   PID_ROLL_INTEGRATION_LIMIT : constant := 20.0;

   PID_PITCH_KP                : constant := 3.5;
   PID_PITCH_KI                : constant := 2.0;
   PID_PITCH_KD                : constant := 0.0;
   PID_PITCH_INTEGRATION_LIMIT : constant := 20.0;

   PID_YAW_KP                : constant := 0.0;
   PID_YAW_KI                : constant := 0.0;
   PID_YAW_KD                : constant := 0.0;
   PID_YAW_INTEGRATION_LIMIT : constant := 360.0;

   DEFAULT_PID_INTEGRATION_LIMIT : constant := 5000.0;

end Pid_Parameters;
