(in-package :yadfa)
(clim:define-command-table yadfa-menu-commands)
(clim:define-command (yadfa-set-eol-action :command-table yadfa-menu-commands :menu "Set EOL Action")
    ((keyword '(member :scroll :allow :wrap :wrap*)
              :prompt "Keyword"))
  (setf (clim:stream-end-of-line-action clim-listener::*query-io*) keyword))
(clim:define-command (yadfa-gc :command-table yadfa-menu-commands :menu "GC")
    ()
  (trivial-garbage:gc :full t))
(unless
    (clim:find-menu-item "Yadfa" (clim:find-command-table 'clim-listener::listener) :errorp nil)
  (clim:add-menu-item-to-command-table (clim:find-command-table 'clim-listener::listener) "Yadfa" :menu (clim:find-command-table 'yadfa-menu-commands)))
(pushnew (clim:find-command-table 'yadfa-menu-commands) (clim:command-table-inherit-from (clim:find-command-table 'clim-listener::listener)))
(clim:define-presentation-action zone-presentation-menu
    (zone nil clim:global-command-table
          :documentation "Menu"
          :menu nil
          :gesture :menu)
  (object presentation frame window x y)
  (declare (ignore object))
  (clim:call-presentation-menu presentation clim:*input-context*
                               frame window x y
                               :for-menu t
                               :label (format nil "Operation on ~A"
                                              (clim:presentation-type presentation))))
(clim:define-command (com-yadfa-move :command-table clim:global-command-table :menu t :name "Move Here")
    ((zone zone))
  (block nil
    (apply #'yadfa-world:move
           (cond
             (*battle*
              (format t "You can't do this in battle~%")
              (return))
             ((and
               (<
                (first (position-of (player-of *game*)))
                (first (position-of zone)))
               (=
                (second (position-of (player-of *game*)))
                (second (position-of zone)))
               (=
                (third (position-of (player-of *game*)))
                (third (position-of zone)))
               (equal
                (fourth (position-of (player-of *game*)))
                (fourth (position-of zone))))
              (iter (for i
                         from (1+ (first (position-of (player-of *game*))))
                         to (first (position-of zone)))
                    (collect :east)))
             ((and
               (>
                (first (position-of (player-of *game*)))
                (first (position-of zone)))
               (=
                (second (position-of (player-of *game*)))
                (second (position-of zone)))
               (=
                (third (position-of (player-of *game*)))
                (third (position-of zone)))
               (equal
                (fourth (position-of (player-of *game*)))
                (fourth (position-of zone))))
              (iter (for i
                         from (1- (first (position-of (player-of *game*))))
                         downto (first (position-of zone)))
                    (collect :west)))
             ((and
               (=
                (first (position-of (player-of *game*)))
                (first (position-of zone)))
               (<
                (second (position-of (player-of *game*)))
                (second (position-of zone)))
               (=
                (third (position-of (player-of *game*)))
                (third (position-of zone)))
               (equal
                (fourth (position-of (player-of *game*)))
                (fourth (position-of zone))))
              (iter (for i
                         from (1+ (second (position-of (player-of *game*))))
                         to (second (position-of zone)))
                    (collect :south)))
             ((and
               (=
                (first (position-of (player-of *game*)))
                (first (position-of zone)))
               (>
                (second (position-of (player-of *game*)))
                (second (position-of zone)))
               (=
                (third (position-of (player-of *game*)))
                (third (position-of zone)))
               (equal
                (fourth (position-of (player-of *game*)))
                (fourth (position-of zone))))
              (iter (for i
                         from (1- (second (position-of (player-of *game*))))
                         downto (second (position-of zone)))
                    (collect :north)))
             (t
              (format t "You're either already on that zone or you tried specifying a path that involves turning (which this interface can't do because Pouar sucks at writing code that generates paths)~%")
              (return))))))
(clim:define-command (com-yadfa-describe-zone :command-table clim:global-command-table :menu t :name "Print Zone Description")
    ((zone zone))
  (yadfa-bin:lst :describe-zone zone))
(clim:define-presentation-to-command-translator com-describe-object-translator
    (yadfa-class climi::com-describe clim:global-command-table
                 :gesture :describe
                 :documentation "Describe"
                 :pointer-documentation "Describe"
                 :tester ((object presentation)
                          (declare (ignore object))
                          (not (eq presentation climi::*null-presentation*)))
                 :menu nil)
  (object)
  (list object))
(clim:define-presentation-to-command-translator com-yadfa-move-translator
    (zone com-yadfa-move clim:global-command-table
          :documentation "Move"
          :pointer-documentation "Move Here"
          :gesture nil
          :menu t)
  (object)
  (list object))
(clim:define-presentation-to-command-translator com-yadfa-describe-zone-translator
    (zone com-yadfa-describe-zone clim:global-command-table
          :documentation "Print Zone Description"
          :pointer-documentation "Print Zone Description"
          :gesture nil
          :menu t)
  (object)
  (list object))
