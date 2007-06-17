(* Copyright (C) 2007 SSH Communications Security, Helsinki, Finland
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

(* XXX Devise a better hash function.  This is not pretty. *)

functor WithHash (Arg : WITH_HASH_DOM) : HASH_GENERIC = struct
   (* <-- SML/NJ workaround *)
   open TopLevel
   infix  7 *`
   infix  6 +`
   infix  4 <\ \>
   infixr 4 </ />
   infix  2 >| andAlso
   infixr 2 |<
   infix  1 orElse >>=
   infix  0 &
   infixr 0 -->
   (* SML/NJ workaround --> *)

   open GenericsUtil

   structure W = Word

   type 'a t = 'a -> {maxWidth : Int.t, maxDepth : Int.t} -> Word.t UnOp.t

   structure HC : sig
      val map : ('b -> 'a) -> 'a t -> 'b t
      val withConst : Word.t -> 'a t UnOp.t
      val lift : ('a -> Word.t) -> 'a t
   end = struct
      fun map b2a hA = hA o b2a
      fun withConst w hA a p r = hA a p (W.+ (w, r))
      fun lift toWord a _ r = r * 0w19 + toWord a
   end

   structure Closed = MkClosedGenericRep (type 'a t = 'a t)
   structure Hash = LayerGenericRep (structure Outer = Arg.Rep and Rep = Closed)
   open Hash.This

   fun hash t v = getT t v {maxWidth = 200, maxDepth = 10} 0wx2CA4B13

   structure Layered = LayerGeneric
     (structure Rep = Closed and Outer = Arg and Result = Hash
      fun iso' bH (a2b, _) = bH o a2b
      fun iso ? = iso' (getT ?)
      fun isoProduct ? = iso' (getP ?)
      fun isoSum ? = iso' (getS ?)

      fun op *` (aT, bT) (a & b) {maxWidth, maxDepth} = let
         val aN = Arg.numElems aT
         val bN = Arg.numElems bT
         val aW = Int.quot (maxWidth * aN, aN + bN)
         val bW = maxWidth - aW
      in
         getP bT b {maxWidth = bW, maxDepth = maxDepth} o
         getP aT a {maxWidth = aW, maxDepth = maxDepth}
      end

      fun op +` ? =
          Sum.sum (Pair.map (HC.withConst 0wx96BA232 o getS,
                             HC.withConst 0wxCF24651 o getS) ?)

      val Y = Tie.function

      fun op --> _ = failing "Hash.--> unsupported"

      fun exn _ = failing "Hash.exn unsupported"
      fun regExn _ _ = ()

      fun refc aT = HC.withConst 0wx178A2346 (HC.map ! (getT aT))

      fun list xT xs {maxWidth, maxDepth} h = let
         val m = Int.quot (maxWidth, 2)
         fun len n []      = n
           | len n (_::xs) = if m <= n then n else len (n+1) xs
         val n = len 0 xs
         val p = {maxWidth = Int.quot (maxWidth, n),
                  maxDepth = maxDepth - 1}
         fun lp h _ []      = h
           | lp h n (x::xs) = if n = 0 then h else lp (getT xT x p h) (n-1) xs
      in
         lp h n xs
      end

      fun hashSeq length sub hashElem s {maxWidth, maxDepth} h = let
         val n = length s
      in
         case Int.min (Int.quot (maxWidth+3, 4), Int.quot (n+1, 2)) of
            0          => h
          | numSamples => let
               val p = {maxWidth = Int.quot (maxWidth, numSamples),
                        maxDepth = maxDepth - 1}
               fun lp h 0 = h
                 | lp h n = lp (hashElem (sub (s, n-1)) p h) (n-1)
            in
               lp h (Int.max (numSamples, Int.min (10, n)))
            end
      end

      fun array aT = hashSeq Array.length Array.sub (getT aT)
      fun vector aT = hashSeq Vector.length Vector.sub (getT aT)

      val char = HC.lift (Word.fromInt o ord)
      val string = hashSeq String.length String.sub char
      val unit = HC.lift (Thunk.mk 0wx2F785)

      val largeInt =
          HC.lift (W.fromLargeInt o LargeInt.rem /> W.toLargeInt W.maxValue)
      val largeWord =
          HC.lift (W.fromLarge o LargeWord.mod /> W.toLarge W.maxValue)
      val word8 = HC.lift Word8.toWord
   (* val word16 = HC.lift Word16.toWord (* Word16 not provided by SML/NJ *) *)
      val word32 = HC.lift (Word.fromLarge o Word32.toLarge)
      val word64 = HC.lift (Word.fromLarge o Word64.toLarge)
      val bool = HC.lift (fn true => 0wx2DA745 | false => 0wx3C24A62)
      val int = HC.lift Word.fromInt
      val word = HC.lift id

      (* XXX SML/NJ does not provide a function to convert a real to bits *)
      val largeReal = HC.map LargeReal.toString string
      val real = HC.map Real.toString string

      (* Trivialities *)

      val T = getT
      fun R _= getT
      fun tuple aP a p = if #maxWidth p = 0 then id else (getP aP) a p
      val record = tuple

      fun C0 _ = unit
      fun C1 _ = getT

      fun data aS a {maxDepth, maxWidth} =
          if maxDepth = 0 then id
          else getS aS a {maxDepth = maxDepth - 1,
                          maxWidth = Int.quot (maxWidth, 2)})

   open Layered
end