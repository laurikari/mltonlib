(* Copyright (C) 2006 SSH Communications Security, Helsinki, Finland
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 *)

structure Thunk :> THUNK = struct
   type 'a t = unit -> 'a
   val mk = Fn.const
end