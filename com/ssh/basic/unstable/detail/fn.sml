(* Copyright (C) 2006 SSH Communications Security, Helsinki, Finland
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 *)

structure Fn :> FN = struct
   type ('a, 'b) t = 'a -> 'b
   fun map (f, g) h = g o h o f
   fun const x _ = x
   fun curry f x y = f (x, y)
   fun failing e _ = raise e
   fun flip f x y = f y x
   fun id x = x
   fun uncurry f (x, y) = f x y
   val op o = op o
   fun undefined _ = raise Fail "undefined"
   fun op <\ (x, f) y = f (x, y)
   fun op \> (f, y) = f y
   fun op /> (f, y) x = f (x, y)
   fun op </ (x, f) = f x
   val op >| = op </
   val op |< = op \>
end
