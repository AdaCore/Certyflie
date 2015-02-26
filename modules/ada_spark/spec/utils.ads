with Interfaces; use Interfaces;

package Utils is

   --  Constants
   PORT_MAX_DELAY : constant Unsigned_32 := 16#ffffffff#;

   --  Types
   subtype Allowed_Floats is Float range -100_000.0 .. 100_000.0;

end Utils;
