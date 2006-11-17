(* Copyright (C) 2006 SSH Communications Security, Helsinki, Finland
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 *)

structure Order :> ORDER = struct
   datatype t = datatype order
   val swap = fn LESS    => GREATER
               | EQUAL   => EQUAL
               | GREATER => LESS
   fun isEqual   x = x = EQUAL
   fun isGreater x = x = GREATER
   fun isLess    x = x = LESS
   val orWhenEq = fn (EQUAL, th) => th ()
                   | (other,  _) => other
end
