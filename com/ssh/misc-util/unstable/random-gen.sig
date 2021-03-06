(* Copyright (C) 2007 SSH Communications Security, Helsinki, Finland
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

(*
 * A signature for random value generators.  The design is based on the
 * QuickCheck library by Koen Claessen and John Hughes:
 *
 *   http://www.cs.chalmers.se/~rjmh/QuickCheck/ .
 *)

signature RANDOM_GEN = sig
   structure RNG : RNG

   type 'a dom and 'a cod
   type 'a t = 'a dom -> 'a cod

   val generate : Int.t -> RNG.t -> 'a t -> 'a

   val lift : (RNG.t -> 'a) -> 'a t

   include MONAD_CORE where type 'a monad = 'a t

   structure Monad : MONAD where type 'a monad = 'a t

   val promote : ('a -> 'b t) -> ('a -> 'b) t

   val Y : 'a t Tie.t

   val variant : Int.t -> 'a t UnOp.t
   val mapUnOp : ('a, 'b) Iso.t -> 'b t UnOp.t -> 'a t UnOp.t

   val sized : (Int.t -> 'a t) -> 'a t
   val resize : Int.t UnOp.t -> 'a t UnOp.t

   val elements : 'a List.t -> 'a t
   val oneOf : 'a t List.t -> 'a t
   val frequency : (Int.t * 'a t) List.t -> 'a t

   val inRange : ('b Sq.t -> 'b t) -> ('a, 'b) Iso.t -> 'a Sq.t -> 'a t

   val intInRange  : Int.t  Sq.t -> Int.t  t
   val realInRange : Real.t Sq.t -> Real.t t
   val wordInRange : Word.t Sq.t -> Word.t t

   val bool : Bool.t t

   val list : 'a t -> Int.t -> 'a List.t t
end
