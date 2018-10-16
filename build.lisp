;; -*- mode: common-lisp; -*-
#-quicklisp
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                          (user-homedir-pathname))))
    (when (probe-file quicklisp-init)
        (load quicklisp-init)))
#+(and gmp sbcl) (require 'sb-gmp)
#+(and sbcl gmp) (sb-gmp:install-gmp-funs)
(when (position "ironclad" (uiop:command-line-arguments) :test #'string=)
    (pushnew :ironclad *features*))
(when (position "slynk" (uiop:command-line-arguments) :test #'string=)
    (pushnew :slynk *features*))
(when (position "swank" (uiop:command-line-arguments) :test #'string=)
    (pushnew :swank *features*))
(when (position "ft" (uiop:command-line-arguments) :test #'string=)
    (pushnew :mcclim-ffi-freetype *features*))
(when (position "texi" (uiop:command-line-arguments) :test #'string=)
    (pushnew :yadfa/docs *features*))
(when (position "mods" (uiop:command-line-arguments) :test #'string=)
    (pushnew :yadfa/mods *features*))
(ql:quickload :yadfa)
(asdf:make :yadfa :force (when (position "force" (uiop:command-line-arguments) :test #'string=) t))
