;;;; -*- mode: Common-Lisp; sly-buffer-package: "yadfa"; coding: utf-8-unix; -*-
(in-package :yadfa)
(declaim (inline make-event event-id event-lambda event-predicate event-repeatable event-major event-major-depends event-optional event-finished-depends event-attributes make-action action-documentation action-attributes action-lambda copy-event copy-action event-p action-p))
(defstruct event
  "An event in the game"
  (id nil
   :type symbol)
  (lambda '(lambda (self)
            (declare (ignore self)) nil)
    :type (or list symbol function))
  (predicate '(lambda (self)
               (declare (ignore self)) t)
   :type (or list function))
  (repeatable nil :type boolean)
  (major nil :type boolean)
  (major-depends nil :type symbol)
  (optional nil)
  (finished-depends '() :type list)
  (attributes ()))
(defstruct action
  "An action for a prop or item"
  (documentation nil :type (or null simple-string))
  (attributes ())
  (lambda '(lambda (prop))
    :type (or list symbol function)))
