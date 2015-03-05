with Types; use Types;
with IMU_Pack; use IMU_Pack;
with Pid_Parameters; use Pid_Parameters;
with Pid_Pack;
pragma Elaborate_All (Pid_Pack);

package Controller_Pack
with SPARK_Mode
is
   --  PID Generic package initizalization
   package Attitude_Pid is new Pid_Pack (T_Angle'First,
                                         T_Angle'Last,
                                         Float'First / 4.0,
                                         Float'Last / 4.0,
                                         MIN_ATTITUDE_COEFF,
                                         MAX_ATTITUDE_COEFF);

   package Rate_Pid is new Pid_Pack (T_Rate'First,
                                     T_Rate'Last,
                                     Float'First / 4.0,
                                     Float'Last / 4.0,
                                     MIN_RATE_COEFF,
                                     MAX_RATE_COEFF);
   --  Global variables
   Roll_Rate_Pid  : Rate_Pid.Pid_Object;
   Roll_Pid       : Attitude_Pid.Pid_Object;
   Pitch_Rate_Pid : Rate_Pid.Pid_Object;
   Pitch_Pid      : Attitude_Pid.Pid_Object;
   Yaw_Rate_Pid   : Rate_Pid.Pid_Object;
   Yaw_Pid        : Attitude_Pid.Pid_Object;

   Roll_Output  : Integer := 0;
   Pitch_Output : Integer := 0;
   Yaw_Output   : Integer := 0;

   Is_Init : Boolean := False;

   --  Procedures and functions

   --  Initalize all the PID's needed for the drone.
   procedure Controller_Init
     with
       Global => (Output => (Roll_Rate_Pid,
                             Roll_Pid,
                             Pitch_Rate_Pid,
                             Pitch_Pid,
                             Yaw_Rate_Pid,
                             Yaw_Pid,
                             Is_Init));

   --  Test if the PID's have been initialized.
   function Controller_Test return Boolean
     with
       Global => (Input => Is_Init);

   --  Update the rate PID's for each axis (Roll, Pitch, Yaw)
   --  given the measured values along each axis and the desired
   --  values retrieved from the corresponding
   --  attitude PID's.
   procedure Controller_Correct_Rate_PID (Roll_Rate_Actual   : T_Rate;
                                          Pitch_Rate_Actual  : T_Rate;
                                          Yaw_Rate_Actual    : T_Rate;
                                          Roll_Rate_Desired  : T_Rate;
                                          Pitch_Rate_Desired : T_Rate;
                                          Yaw_Rate_Desired   : T_Rate)
     with
       Global => (In_Out => (Roll_Rate_Pid, Pitch_Rate_Pid, Yaw_Rate_Pid));

   --  Update the attitude PID's for each axis given (Roll, Pitch, Yaw)
   --  given the measured values along each axis and the
   --  desired values retrieved from the commander.
   procedure Controller_Correct_Attitude_Pid
     (Euler_Roll_Actual   : T_Angle;
      Euler_Pitch_Actual  : T_Angle;
      Euler_Yaw_Actual    : T_Angle;
      Euler_Roll_Desired  : T_Angle;
      Euler_Pitch_Desired : T_Angle;
      Euler_Yaw_Desired   : T_Angle)
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
