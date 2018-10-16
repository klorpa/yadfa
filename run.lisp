;; -*- mode: common-lisp; -*-
(declaim (optimize (debug 2)))
#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                          (user-homedir-pathname))))
    (when (probe-file quicklisp-init)
        (load quicklisp-init)))
#+(and gmp sbcl) (require 'sb-gmp)
#+(and sbcl gmp) (sb-gmp:install-gmp-funs)
(when (position "ironclad" (uiop:command-line-arguments) :test #'string=)
    (pushnew :ironclad *features*))
(ql:quickload :slynk)
(ql:quickload :swank)
(when (position "slynk" (uiop:command-line-arguments) :test #'string=)
    #+slynk (slynk::create-server :dont-close t))
(when (position "swank" (uiop:command-line-arguments) :test #'string=)
    #+swank(swank::create-server :dont-close t))
(when (position "ft" (uiop:command-line-arguments) :test #'string=)
    (pushnew :mcclim-ffi-freetype *features*))
(when (position "texi" (uiop:command-line-arguments) :test #'string=)
    (pushnew :yadfa/docs *features*))
(when (position "mods" (uiop:command-line-arguments) :test #'string=)
    (pushnew :yadfa/mods *features*))
(when (position "wait" (uiop:command-line-arguments) :test #'string=)
    (sleep 2))
(ql:quickload :yadfa)
(in-package :yadfa)
(yadfa::main)
