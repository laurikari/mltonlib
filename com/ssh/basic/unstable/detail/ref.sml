(* Copyright (C) 2006 SSH Communications Security, Helsinki, Finland
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 *)

structure Ref : REF = struct
   type 'a t = 'a ref
   val new = ref
   val ! = !
   val op := = op :=
   fun op :=: (r1, r2) = let
      val v1 = !r1
      val v2 = !r2
   in
      r1 := v2
    ; r2 := v1
   end
   fun exchange (r, v) = !r before r := v
   fun app ef = ef o !
   fun map f = new o f o !
   fun modify f r = r := f (!r)
   val equal = op =
end
