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

   procedure Controller_Init with
     Global => (Output => (Roll_Rate_Pid, Roll_Pid, Pitch_Rate_Pid, Pitch_Pid,
                           Yaw_Rate_Pid, Yaw_Pid, Is_Init));

   function Controller_Test return Boolean with
     Global => (Input => Is_Init);

   procedure Controller_Correct_Rate_PID(Roll_Rate_Actual   : Allowed_Floats;
                                         Pitch_Rate_Actual  : Allowed_Floats;
                                         Yaw_Rate_Actual    : Allowed_Floats;
                                         Roll_Rate_Desired  : Allowed_Floats;
                                         Pitch_Rate_Desired : Allowed_Floats;
                                         Yaw_Rate_Desired   : Allowed_Floats) with
     Global => (In_Out => (Roll_Rate_Pid, Pitch_Rate_Pid, Yaw_Rate_Pid)),
     Pre    => PreCondition(Roll_Rate_Pid);

   function PreCondition(Pid : Pid_Object) return Boolean is
       ((Pid.Dt > 0.0 and Pid.Dt < 1.0) and then
     (Pid.Integ >= Pid.I_Limit_Low and Pid.Integ <= Pid.I_Limit) and then
     Pid.Error in 3.0 * Allowed_Floats'First .. 3.0 * Allowed_Floats'Last);

end Controller_Pack;
