(* Copyright (C) 2006 SSH Communications Security, Helsinki, Finland
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 *)

(** Utilities for dealing with unary operators. *)
signature UN_OP = sig
   type 'a t = 'a -> 'a
   (** Type of unary operators (e.g. {~, rev, ...}). *)
end