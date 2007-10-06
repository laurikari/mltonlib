(* Copyright (C) 2007 SSH Communications Security, Helsinki, Finland
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

(* This whole file is a SML/NJ workaround. *)

(*
 * We assume here that {Eq} and {Pretty} have already been provided.  The
 * {Arbitrary} generic is rather specific to randomized testing and has
 * probably little use otherwise.  The same goes for {Shrink}.  The {Size}
 * generic is probably also not used much outside testing.
 *)

signature Generic = sig include Generic ARBITRARY end
structure Generic : Generic = struct
   structure Open = WithArbitrary
     (open Generic
      structure HashRep = Open.Rep and TypeInfoRep = Open.Rep
      structure RandomGen = RanQD1Gen)
   open Generic Open
end

signature Generic = sig include Generic SIZE end
structure Generic : Generic = struct
   structure Open = WithSize
     (open Generic
      structure HashRep = Open.Rep and TypeInfoRep = Open.Rep)
   open Generic Open
end

signature Generic = sig include Generic SHRINK end
structure Generic : Generic = struct
   structure Open = WithShrink
     (open Generic
      structure OrdRep = Open.Rep and SizeRep = Open.Rep)
   open Generic Open
end

structure Generic = struct
   structure Rep = ClosePrettyWithExtra
     (open Generic
      structure PrettyRep = Open.Rep)
   open Generic Rep
end