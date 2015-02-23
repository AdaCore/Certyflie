with Interfaces; use Interfaces;

package Utils is

   --  Constants
   PORT_MAX_DELAY : constant Unsigned_32 := 16#ffffffff#;

   --  Types
   subtype Allowed_Float_values is Float range -5_000.0 .. 5_000.0;

end Utils;
