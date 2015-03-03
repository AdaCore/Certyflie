with Pid_Pack; use Pid_Pack;
with Utils; use Utils;

package Controller_Pack
  with SPARK_Mode
is
   --  Global variables
   Roll_Rate_Pid  : Pid_Object;
   Roll_Pid       : Pid_Object;
   Pitch_Rate_Pid : Pid_Object;
   Pitch_Pid      : Pid_Object;
   Yaw_Rate_Pid   : Pid_Object;
   Yaw_Pid        : Pid_Object;

   Roll_Output  : Integer := 0;
   Pitch_Output : Integer := 0;
   Yaw_Output   : Integer := 0;

   Is_Init : Boolean := False;

   --  Procedures and functions

   --  Initalize all the PID's needed for the drone.
   procedure Controller_Init
     with
     Global => (Output => (Roll_Rate_Pid, Roll_Pid, Pitch_Rate_Pid, Pitch_Pid,
                           Yaw_Rate_Pid, Yaw_Pid, Is_Init));

   --  Test if the PID's have been initialized.
   function Controller_Test return Boolean
     with
     Global => (Input => Is_Init);

   --  Update the rate PID's for each axis (Roll, Pitch, Yaw)
   --  given the measured values along each axis and the desired
   --  values retrieved from the corresponding
   --  attitude PID's.
   procedure Controller_Correct_Rate_PID (Roll_Rate_Actual   : Allowed_Floats;
                                         Pitch_Rate_Actual  : Allowed_Floats;
                                         Yaw_Rate_Actual    : Allowed_Floats;
                                         Roll_Rate_Desired  : Allowed_Floats;
                                         Pitch_Rate_Desired : Allowed_Floats;
                                         Yaw_Rate_Desired   : Allowed_Floats)
     with
     Global => (In_Out => (Roll_Rate_Pid, Pitch_Rate_Pid, Yaw_Rate_Pid));

   --  Update the attitude PID's for each axis given (Roll, Pitch, Yaw)
   --  given the measured values along each axis and the
   --  desired values retrieved from the commander.
   procedure Controller_Correct_Attitude_Pid
     (Euler_Roll_Actual   : Allowed_Floats;
      Euler_Pitch_Actual  : Allowed_Floats;
      Euler_Yaw_Actual    : Allowed_Floats;
      Euler_Roll_Desired  : Allowed_Floats;
      Euler_Pitch_Desired : Allowed_Floats;
      Euler_Yaw_Desired   : Allowed_Floats)
     with
     Global => (In_Out => (Roll_Pid, Pitch_Pid, Yaw_Pid));

   --  Reset all the PID's error values.
   procedure Controller_Reset_All_Pid
     with
     Global => (In_Out => (Roll_Rate_Pid, Pitch_Rate_Pid, Yaw_Rate_Pid,
                           Roll_Pid, Pitch_Pid, Yaw_Pid));

   --  Get the output of the rate PID's.
   --  Must be called after 'Controller_Correct_Rate_Pid' to update the PID's.
   procedure Controller_Get_Actuator_Output (Actuator_Roll  : out Integer;
                                            Actuator_Pitch : out Integer;
                                            Actuator_Yaw   : out Integer)
     with
     Global => (Input => (Roll_Rate_Pid, Pitch_Rate_Pid, Yaw_Rate_Pid));

   --  Get the output of the attitude PID's, which will command the rate PID's.
   --  Must be called after 'Controller_Correct_Attitude_Pid' to update
   --  the PID's.
   procedure Controller_Get_Desired_Rate (Roll_Rate_Desired  : out Integer;
                                         Pitch_Rate_Desired : out Integer;
                                         Yaw_Rate_Desired   : out Integer)
     with
     Global => (Input => (Roll_Pid, Pitch_Pid, Yaw_Pid));
end Controller_Pack;
