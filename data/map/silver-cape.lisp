(in-package :yadfa-zones)
(macro-level
    `(progn
         ,@(iter (for i from 0 to 20)
               (collect
                   `(ensure-zone (0 ,i 0 silver-cape)
                        :name "Silver Cape Street"
                        :description "A busy street with various furries moving back and forth"
                        :enter-text "You enter the street"
                        :warp-points ,(when (= i 0) '(list 'bandits-domain '(0 30 0 bandits-domain)))
                        :hidden ,(when (= i 0) t)
                        ,@(when (= i 0) '(:events (list 'yadfa-events:enter-silver-cape-1))))))))
(macro-level
    `(progn
         ,@(iter (for i from -10 to 10)
               (unless (= i 0)
                   (collect
                       `(ensure-zone (,i 10 0 silver-cape)
                            :name "Silver Cape Street"
                            :description "A busy street with various furries moving back and forth"
                            :enter-text "You enter the street"))))))
(ensure-zone (-1 6 0 silver-cape)
    :name "Silver Cape Navy HQ Entrance"
    :description "The entrance to Navy HQ."
    :enter-text "You're inside Navy HQ. The navy here seems to mostly consist of various aquatic creatures. They're mostly potty trained but still wear pullups just in case they don't make it in time, or if they don't want to hold it any longer. Due to pullups having a lower capacity than diapers, some of them suppliment pullups with stuffers.")
(ensure-zone (-2 6 -1 silver-cape)
    :name "Silver Cape Jail"
    :description "The jail beneith Navy HQ"
    :enter-text "You're inside Navy HQ"
    :locked nil
    :events (list 'yadfa-events:get-location-to-pirate-cove-1))
(ensure-zone (-2 6 0 silver-cape)
    :name "Silver Cape Navy HQ Lobby"
    :description "The lobby of Navy HQ"
    :enter-text "You're inside Navy HQ. A guard doing a potty dance in a soggy pullup is guarding the entrance to the Jail underneath"
    :props (list
               :guard
               (make-instance 'prop
                   :name "Dolphin Navy Guard"
                   :description "The dolphin is hopping around while holding the front of his soggy pullups squishing with each hop"
                   :actions
                   (list
                       :talk
                       (make-action
                           :documentation "Talk to the guard"
                           :lambda
                           '(lambda
                                (prop &rest keys &key &allow-other-keys)
                                (declare (type prop prop) (ignore prop))
                                (check-type prop prop)
                                (write-line "Dolphin: Welcome to navy HQ")
                                (format t "~a: Why don't you go to the bathroom and change your pullups?~%" (name-of (player-of *game*)))
                                (write-line "Dolphin: I'm not allowed to go to the bathroom during my shift and if I leak again they'll put me back in diapers and put me in the nursery.")
                                (format t "~a: Ok~%" (name-of (player-of *game*)))
                                (setf (getf-action-from-prop
                                          (position-of (player-of *game*))
                                          :guard
                                          :tickle)
                                    (make-action
                                        :documentation "Tickle the dolphin"
                                        :lambda
                                        '(lambda
                                             (prop &rest keys &key &allow-other-keys)
                                             (declare (type prop prop) (ignore prop))
                                             (write-line "Dolphin: ACK!! NO!! PLEASE!!! DON'T!!!")
                                             (write-line "*The dolphin giggles and thrashes about then leaves a puddle on the floor*")
                                             (write-line "*One of the Navy orcas take notice and crinkles over*")
                                             (write-line "Orca: Looks like the baby dolphin still hasn't learned to not leave puddles everywhere")
                                             (write-line "Dolphin: I'm not a baby!!!")
                                             (write-line "Orca: Says the baby in leaky pullups. Since you keep leaving puddles, we're putting you back in diapers.")
                                             (write-line "*The Orca lays the dolphin on the floor*")
                                             (write-line "Dolphin: Please don't change me here!!! Everyone can see me!!!!!")
                                             (write-line "*The Orca ignores his pleas and changes his soggy pullups and puts him in a thick diaper then stands him back up. The diaper is so thick that his legs are forced apart. The dolphin hides his face in embarrassment as he is escorted to a nursery*")
                                             (write-line "*The Jail beneith the cell is now unguarded and can be entered*")
                                             (setf (lockedp (get-zone '(-2 6 -1 silver-cape))) :nil
                                                 (enter-text-of (get-zone (-2 6 0 silver-cape))) "You're inside Navy HQ.")
                                             (remf (get-props-from-zone (position-of (player-of *game*)))
                                                 :guard))))
                                (setf (getf-action-from-prop
                                          (position-of (player-of *game*))
                                          :guard
                                          :give-pad)
                                    (make-action
                                        :documentation "Give the dolphin a stuffer so he can go without making a puddle"
                                        :lambda
                                        '(lambda
                                             (prop &rest keys &key &allow-other-keys)
                                             (declare (type prop prop) (ignore prop))
                                             (block nil
                                                 (let
                                                     ((a
                                                          (iter (for i in (inventory-of (player-of *game*)))
                                                              (when (and
                                                                        (typep i
                                                                            'yadfa:incontinence-pad)
                                                                        (<= (sogginess-of i)
                                                                            0))
                                                                  (collect i)))))
                                                     (unless
                                                         a
                                                         (write-line "You don't have a clean stuffer to give her")
                                                         (return))
                                                     (write-line "*You hand the dolphin a stuffer*")
                                                     (format t "~a: Here, you might want this" (name-of (player-of *game*)))
                                                     (write-line "Dolphin: I'm no infant. I can hold it in.")
                                                     (write-line "*The dolphin panics as his bladder leaks a little*")
                                                     (write-line "Dolphin: Ok ok, I'll take them.")
                                                     (write-line "*The dolphin quickly inserts the stuffer into his pullups and floods himself*")
                                                     (write-line "Dolphin: Don't tell anyone about this incident and I'll let you through")
                                                     (write-line "*The Jail beneith can now be entered*")
                                                     (removef (inventory-of (player-of *game*)) (car a))
                                                     (setf (lockedp (get-zone '(-2 6 -1 silver-cape)))
                                                         :nil
                                                         (enter-text-of (get-zone (-2 6 0 silver-cape)))
                                                         "You're inside Navy HQ."
                                                         (actions-of
                                                             (getf (get-props-from-zone
                                                                       (position-of (player-of *game*)))
                                                                 :guard))
                                                         (list
                                                             :talk
                                                             (make-action
                                                                 :documentation "Talk to the guard"
                                                                 :lambda
                                                                 '(lambda
                                                                      (prop &rest keys &key &allow-other-keys)
                                                                      (declare (type prop prop) (ignore prop))
                                                                      (write-line "Dolphin: Welcome to navy HQ"))))
                                                         (description-of
                                                             (getf (get-props-from-zone
                                                                       (position-of (player-of *game*)))
                                                                 :guard))
                                                         "A dolphin wearing pullups"))))))))))))
(ensure-zone (1 5 0 silver-cape)
    :name "Silver Cape Pokemon Center"
    :description "A place to heal your pokemon"
    :enter-text "You enter the street"
    :props (list
               :magic-healing-machine
               (make-instance 'prop
                   :name "Magic Healing Machine"
                   :description "Heal your pokemon here"
                   :actions (list
                                :use (make-action
                                         :documentation "Heal your pokemon"
                                         :lambda '(lambda
                                                      (prop &rest keys &key &allow-other-keys)
                                                      (declare (type prop prop) (ignore prop))
                                                      (check-type prop prop)
                                                      (format t "~a~%" "https://youtu.be/wcg5n2UVMss?t=134")
                                                      (setf (health-of user) (calculate-stat user :health))
                                                      (setf (energy-of user) (calculate-stat user :energy))))))))
(ensure-zone (0 21 0 silver-cape)
    :name "Silver Cape Dock"
    :description "A Dock that heads to the ocean"
    :enter-text "You enter the street"
    :warp-points (list :your-ship '(-1 6 0 yadfa-zones:your-ship)))

(ensure-zone (-6 9 0 silver-cape)
    :name "Silver Cape Recycling Center"
    :description "Welcome To Silver Cape Recycling Center. We take all your crap, send it to a recycling plant across the country in a truck belching smoke and polution, process your crap to turn it into less quality crap in machines belching more smoke and pollution, stockpile it and beg people to buy it, then send it all to ~a's garbage collector. Think of it as a more expensive and less environmentally friendly way to throw your stuff away."
    :enter-text "Welcome To Silver Cape Recycling Center. We take all your crap, send it to a recycling plant across the country in a truck belching smoke and polution, process your crap to turn it into less quality crap in machines belching more smoke and pollution, stockpile it and beg people to buy it, then send it all to ~a's garbage collector. Think of it as a more expensive and less environmentally friendly way to throw your stuff away."
    :props (list
               :recycling-bin
               (make-instance 'prop
                   :name "Magic Recycling Bin"
                   :description "Throw your crap here and pretend it gets recycled into itself. Use the :TOSS action instead of YADFA-WORLD:PLACE because this game's \"engine\" is too stupid to figure out what to do with it otherwise."
                   :actions (list
                               :toss
                               (make-action
                                   :documentation "Toss your items"
                                   :lambda '(lambda
                                                (prop &rest keys &key items &allow-other-keys)
                                                (declare
                                                    (type prop prop)
                                                    (type list items)
                                                    (ignore keys))
                                                (check-type prop prop)
                                                (check-type items list)
                                                (block lambda
                                                    (let ((items (sort (remove-duplicates items) #'<)))
                                                        (setf items (iter
                                                                        (generate i in items)
                                                                        (for j in (inventory-of (player-of *game*)))
                                                                        (for k upfrom 0)
                                                                        (when (first-iteration-p)
                                                                            (next i))
                                                                        (when (= k i)
                                                                            (collect j)
                                                                            (next i))))
                                                        (unless items
                                                            (format t "Those items aren't valid")
                                                            (return-from block))
                                                        (iter (for i in items)
                                                            (when (not (tossablep i))
                                                                (format t "To avoid breaking the game, we don't accept your ~a~%~%"
                                                                    (name-of i))
                                                                (return-from lambda))
                                                            (iter (for i in items)
                                                                (format t
                                                                    "You toss your ~a into the bin and pretend you're saving the planet~%"
                                                                    (name-of i)))
                                                            (alexandria:removef (inventory-of (player-of *game*)) items
                                                                :test (lambda (o e)
                                                                          (member e o))))))))))))
