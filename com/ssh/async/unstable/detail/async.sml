(* Copyright (C) 2007-2008 SSH Communications Security, Helsinki, Finland
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)

structure Async :> ASYNC = struct
   (* <-- SML/NJ workaround *)
   open TopLevel
   infix <|>
   (* SML/NJ workaround --> *)

   exception Full

   structure Queue = LinkedQueue

   structure Handler = struct
      datatype 'a t =
         T of {unlink : Unit.t Effect.t Ref.t, effect : 'a Effect.t}
      fun new () = T {unlink = ref Effect.nop, effect = id}
      fun prepend f (T t) = T {unlink = #unlink t, effect = #effect t o f}
      fun pushFront ul (h as T {unlink, ...}) =
          (unlink := !unlink o UnlinkableList.pushFront ul h ; false)
      val handlers : Unit.t Effect.t Queue.t = Queue.new ()
      fun schedule a (T {unlink, effect}) =
          (!unlink () ; Queue.enque handlers (fn () => effect a))
      fun runAll () = Queue.appClear (pass ()) handlers
   end

   structure Event = struct
      datatype 'a t = E of ('a Handler.t UnPr.t, 'a) Sum.t Thunk.t
      fun on (E t) f =
          E (fn () =>
                INL (fn h =>
                        case Handler.prepend f h
                         of h =>
                            case t ()
                             of INL ef => ef h
                              | INR v =>
                                (Handler.schedule
                                  ()
                                  (Handler.prepend (const v) h)
                               ; true)))
      fun (E l) <|> (E r) =
          E (fn () =>
                case l ()
                 of INR v => INR v
                  | INL lEf =>
                    case r ()
                     of INR v => INR v
                      | INL rEf =>
                        INL (fn h => lEf h orelse rEf h))
      val never = E (fn () => INL (const false))
      fun once (E t) =
          case t ()
           of INL ef => ignore (ef (Handler.new ()))
            | INR () => ()
      (* Non primitive functions: *)
      val choose = fn [] => never | e::es => foldl op <|> e es
      fun when ? = once o on ?
      fun each e = when e (fn () => each e)
      fun every ? = each o on ?
      val any = once o choose
      val all = each o choose
      fun whenSeq es done = let
         fun lp rs =
          fn [] => done (rev rs)
           | e::es => when e (fn r => lp (r::rs) es)
      in
         lp [] es
      end
      fun whenArb es done = let
         val n = ref (length es)
         val rs = Array.array (!n, NONE)
      in
         List.appi
          (fn (i, e) =>
              when e (fn v =>
                         (Array.update (rs, i, SOME v)
                        ; n := !n - 1
                        ; if 0 = !n
                          then done (Stream.toList
                                      (Stream.map
                                        valOf (Stream.fromArray rs)))
                          else ())))
          es
      end
   end

   open Event

   structure Ch = struct
      datatype 'a t =
         T of {ts : 'a Handler.t UnlinkableList.t,
               gs : {handler : Unit.t Handler.t, value : 'a} UnlinkableList.t}
      fun new () = T {ts = UnlinkableList.new (), gs = UnlinkableList.new ()}
      fun take (T {gs, ts}) =
          E (fn () =>
                case UnlinkableList.popBack gs
                 of NONE => INL (Handler.pushFront ts)
                  | SOME {handler, value} =>
                    (Handler.schedule () handler ; INR value))
      fun give (T {ts, gs}) v =
          E (fn () =>
                case UnlinkableList.popBack ts
                 of SOME th => (Handler.schedule v th ; INR ())
                  | NONE =>
                    INL (fn h as Handler.T {unlink, ...} =>
                            (unlink := !unlink o UnlinkableList.pushFront
                                                  gs {handler = h, value = v}
                           ; false)))
   end

   structure Mailbox = struct
      datatype 'a t = T of {ts : 'a Handler.t UnlinkableList.t, vs : 'a Queue.t}
      fun new () = T {ts = UnlinkableList.new (), vs = Queue.new ()}
      fun take (T {ts, vs}) =
          E (fn () =>
                case Queue.deque vs
                 of NONE => INL (Handler.pushFront ts)
                  | SOME v => INR v)
      fun send (T {ts, vs}) v =
          (Queue.enque vs v
         ; case UnlinkableList.popBack ts
            of NONE => ()
             | SOME th =>
               case Queue.deque vs
                of NONE => fail "impossible"
                 | SOME v => Handler.schedule v th)
   end

   structure IVar = struct
      datatype 'a t =
         T of {rs : 'a Handler.t UnlinkableList.t, st : 'a Option.t Ref.t}
      fun new () = T {rs = UnlinkableList.new (), st = ref NONE}
      fun read (T {rs, st}) =
          E (fn () =>
                case !st
                 of SOME v => INR v
                  | NONE => INL (Handler.pushFront rs))
      fun whileSome getSome from doSome =
          case getSome from
           of NONE => ()
            | SOME v => (doSome v : Unit.t ; whileSome getSome from doSome)
      fun fill (T {rs, st}) v =
          case !st
           of SOME _ => raise Full
            | NONE => (st := SOME v
                     ; whileSome UnlinkableList.popBack rs (Handler.schedule v))
   end

   structure MVar = struct
      datatype 'a t =
         T of {ts : 'a Handler.t UnlinkableList.t, st : 'a Option.t Ref.t}
      fun new () = T {ts = UnlinkableList.new (), st = ref NONE}
      fun take (T {ts, st}) =
          E (fn () =>
                case !st
                 of SOME v => (st := NONE ; INR v)
                  | NONE => INL (Handler.pushFront ts))
      fun give (T {ts, st}) v =
          case UnlinkableList.popBack ts
           of NONE => st := SOME v
            | SOME h => Handler.schedule v h
      fun fill (t as T {st, ...}) v =
          case !st
           of SOME _ => raise Full
            | NONE => give t v
      fun send (t as T {st, ...}) v =
          case !st
           of SOME _ => st := SOME v
            | NONE => give t v
   end

   structure SkipCh = MVar

   structure Multicast = struct
      datatype 'a n = N of 'a * 'a n IVar.t
      datatype 'a t = T of 'a n IVar.t Ref.t
      fun new () = T (ref (IVar.new ()))
      fun tap (T st) = let
         val ch = Ch.new ()
         fun lp st =
             when (IVar.read st)
                  (fn N (v, st) =>
                      when (Ch.give ch v)
                           (fn () => lp st))
      in
         lp (!st) ; Ch.take ch
      end
      fun send (T st) v = let
         val ost = !st
         val nst = IVar.new ()
      in
         st := nst ; IVar.fill ost (N (v, nst))
      end
   end
end
