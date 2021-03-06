(* Copyright (C) 2006 Stephen Weeks.
 *
 * This code is released under the MLton license, a BSD-style license.
 * See the LICENSE file or http://mlton.org/License for details.
 *)
structure Dir: DIR = struct

   structure Stream = struct
      local
         open OS.FileSys
      in
         type t = dirstream
         val close = closeDir
         val read = Option.ofBasis o readDir
         val rewind = rewindDir
      end
   end

   type t = String.t

   local
      open OS.FileSys
   in
      val changeTo = chDir
      val create = mkDir
      val current = getDir
      val openStream = openDir
      val remove = rmDir
   end

end
