;;;; -*- mode: Common-Lisp; sly-buffer-package: "yadfa-enemies"; coding: utf-8-unix; -*-
(in-package :yadfa-enemies)
(defmethod default-attack ((target team-member) (user ghost))
  (declare (ignore target))
  (f:fmt t (name-of user) " Acts all scary" #\Newline)
  (unless (and (<= (random 5) 0)
               (iter (for i in (if (typep user 'team-member)
                                   (enemies-of *battle*)
                                   (team-of *game*)))
                 (with j = nil)
                 (when (>= (bladder/contents-of i) (bladder/need-to-potty-limit-of i))
                   (format t "~a wets ~aself in fear~%" (name-of i) (if (malep i) "him" "her"))
                   (wet :wetter i)
                   (set-status-condition 'yadfa-status-conditions:wetting i)
                   (setf j t))
                 (when (>= (bowels/contents-of i) (bowels/need-to-potty-limit-of i))
                   (format t "~a messes ~aself in fear~%" (name-of i) (if (malep i) "him" "her"))
                   (mess :messer i)
                   (set-status-condition 'yadfa-status-conditions:messing i)
                   (setf j t))
                 (finally (return j))))
    (write-line "it had no effect")))
