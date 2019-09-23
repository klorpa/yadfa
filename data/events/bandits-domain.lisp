;;;; -*- mode: Common-Lisp; sly-buffer-package: "yadfa-events"; coding: utf-8-unix; -*-
(in-package :yadfa-events)
(defevent enter-bandits-village-1
  :lambda '(lambda (self)
            (declare (ignore self))
            (set-new-battle '((yadfa-enemies:diapered-raccoon-bandit . '(:level 5)))
             :continuable t
             :enter-battle-text (format nil "Raccoon Bandit: This area is under control of the Raccoon Bandits. If you want in you have to get past me~%*Cue battle transition. You can't see it because this is a text based game, but trust us, it's there.*~%"))))
(defevent enter-bandits-shop-1
  :lambda '(lambda (self)
            (declare (ignore self))
            (format t "Diapered Raccoon Bandit Shop Owner: Hey, we got a customer. Stop dancing around pulling on a locked bathroom door and help him out.~%~%")
            (format t "Rookie Diapered Raccoon Bandit Servant: But I really gotta gooooo!!!!! *hops from foot to foot holding the front of his diaper*~%~%")
            (format t "*The shop owner walks over to the servant and starts tickling him*~%~%")
            (format t "Rookie Diapered Raccoon Bandit Servant: NOOOO!!! STOP!!!! I CAN'T HOLD IT!!!!~%~%")
            (format t "*The rookie starts laughing and thrashing about, the insignia that doubles as a wetness indicator on the front of his diaper then turns from blue to yellow.*~%~%")
            (format t "Shop Owner: There, you went, now go see to the customer.~%~%")
            (format t "*The now blushy Rookie Diapered Raccoon Bandit waddles and squishes over to the back of the counter*~%~%")))
(defevent enter-bandits-shop-3
  :predicate '(lambda (self)
               (declare (ignore self))
               (= (random 5) 0))
  :finished-depends (list 'enter-bandits-shop-1)
  :lambda '(lambda (self)
            (declare (ignore self))
            (format t "*The shopkeeper hops around from foot to foot fiddling with the bathroom door with one paw while clutching the front of his diaper with the other*~%~%")
            (format t "Shopkeeper: I can't believe I lost the stupid key!!!!!~%~%")
            (format t "*The shopkeeper turns to you pressing his knees together bobbing up and down with both paws pressed firmly on the front of his diaper*~%~%")
            (format t "Shopkeeper: HELP ME!!!!!~%~%")
            (format t "*~a shrugs and tickles the shopkeeper*~%~%" (name-of (player-of *game*)))
            (format t "Shopkeeper: NOOOO!!!!!! NOT WHAT I MEANT!!!!!~%~%")
            (format t "*The shopkeeper laughs and thrashes about and floods his diapers*~%~%")
            (format t "~a: You're welcome~%~%" (name-of (player-of *game*)))
            (format t "*The shopkeeper blushes heavily and grumbles*~%~%")))
(defevent enter-bandits-shop-2
  :predicate '(lambda (self)
               (declare (ignore self))
               (= (random 5) 0))
  :lambda '(lambda (self)
            (declare (ignore self))
            (write-line "*A diapered Raccoon is doing a potty dance outside the store in a full diaper squishing with every step*")
            (write-line "Raccoon: LET ME IN!!!! I CAN'T HOLD IT MUCH LONGER!!!!")
            (write-line "Shop Owner: Sorry leaky, you're not allowed in the shop since you leave puddles everywhere")
            (write-line "Raccoon: I'M NOT LEAKY!!!! *blushes angrily*")
            (write-line "*The raccoon has an accident and his diaper leaks and leaves puddles everywhere*")
            (write-line "Shop Owner: Then explain the state of your diapers")
            (write-line "*The raccoon blushes then starts to \\sout{waddle away with his legs spread apart} \"sneak away\" hoping no one will notice what he did \\sout{even though the trail he's leaving makes it obvious}*")
            (format t "*~A laughs at the leaky raccoon*~%" (name-of (player-of *game*)))
            (write-line "Leaky raccoon blushing angrily: What are you laughing at?")
            (set-new-battle '((yadfa-enemies:diapered-raccoon-bandit . (list :level (random-from-range 2 5)
                                                                             :wear (list
                                                                                    (make-instance 'yadfa-items:bandit-uniform-tunic)
                                                                                    (make-instance 'yadfa-items:bandit-adjustable-diaper :sogginess 1400
                                                                                                                                         :messiness 8000)))))
             :enter-battle-text (format nil "The leaky raccoon waddles over to you to fight~%"))))
(defevent decend-bandits-cave-1
  :repeatable t
  :lambda '(lambda (self)
            (declare (ignorable self))
            (if (< (random 15) 1)
             (progn
               (format t "You found a treasure chest, use `(interact :chest :take :all)' to take all the treasure from it~%")
               (setf (getf (get-props-from-zone '(6 24 -2 "bandits-domain")) :chest)
                     (make-instance 'prop
                                    :name "Treasure Chest"
                                    :description "A treasure chest"
                                    :items (cond ((< (random 10))
                                                  (list (make-instance 'yadfa-items:gold-collar
                                                                       :value (random-from-range 25000 50000))))
                                                 ((< (random 10))
                                                  (list (make-instance 'yadfa-items:gold-pacifier
                                                                       :value (random-from-range 10000 20000))))
                                                 ((< (random 10))
                                                  (list (make-instance 'yadfa-items:gem
                                                                       :value (random-from-range 25000 50000))))
                                                 ((< (random 20))
                                                  (list (make-instance 'yadfa-items:gold-bar
                                                                       :value (random-from-range 50000 100000)))))
                                    :bitcoins (random-from-range 12500 25000))))
             (remf (get-props-from-zone '(6 24 -2 "bandits-domain")) :chest))
            (cond
              ((< (random 12) 1)
               (set-new-battle '((yadfa-enemies:diapered-raccoon-bandit . (list
                                                                           :level (random-from-range 2 5)
                                                                           :bladder/contents (random-from-range 450 550)))
                                 (yadfa-enemies:diapered-raccoon-bandit . (list
                                                                           :level (random-from-range 2 5)
                                                                           :bladder/contents (random 400)
                                                                           :bowels/contents (random 5000))))
                               :enter-battle-text (format nil "Random Raccoon 1: Hey, I need to take a break. I really gotta go.~%~%Random Raccoon 2: Well you're gonna have to hold it, as we seem to have an intruder.~%~%Random Raccoon 1: But.. but... ooooohhhh *clutches the front of his diaper pressing his knees together*~%~%Time for battle!!!~%~%")))
              ((< (random 12) 1)
               (format t "*~a hears grunting and looks to find one of the raccoons squatting down and messing his pamps. After finishing, he quickly stands up blushing heavily.*~%~%"
                       (name-of (player-of *game*)))
               (format t "Diapered Raccoon Bandit: You didn't see nothing.~%~%")
               (format t "~a: Oh really? *~a lifts up the back of the raccoon's tunic and press hard against the back of the raccoon's diaper hard.*~%~%"
                       (name-of (player-of *game*))
                       (name-of (player-of *game*)))
               (format t "*The raccoon yelps and quickly puts his paws on the back of his diaper struggling to unmush it.*~%~%")
               (when (> (list-length (allies-of *game*)) 0)
                 (if (= (list-length (allies-of *game*)) 1)
                     (format t "*~a ~a*~%~%"
                             (name-of (nth 0 (allies-of *game*)))
                             (if (malep (nth 0 (allies-of *game*)))
                                 "snickers"
                                 "giggles"))
                     (format t "*~a's team mates laugh*~%~%")))
               (format t "Diapered Raccoon Bandit: You're gonna pay for that!!!!~%~%")
               (if (< (random 2) 1)
                   (progn
                     (format t "~a: I think it's you who are going to pay, unless you want me to blab to your friends telling them what you just did.~%~%"
                             (name-of (player-of *game*)))
                     (format t "*A soft hiss can be heard as the raccoon floods his diapers in a panic*~%~%")
                     (format t "Diapered Raccoon Bandit: No please!!! I'll give you anything you want!!!~%~%")
                     (format t "~a: All your money and all your stuff~%~%" (name-of (player-of *game*)))
                     (format t "Diapered Raccoon Bandit: But... but... *groans* alright~%~%")
                     (format t "~a gets everything the raccoon is carrying except the clothes and diapers the raccoon is wearing. The raccoon then waddles off with his legs spread apart like a 5 year old who didn't make it to the toilet in time.~%~%"
                             (name-of (player-of *game*)))
                     (incf (bitcoins-of (player-of *game*)) (random-from-range 50000 100000))
                     (iter (for i from 0 to (random 5))
                       (push (make-instance 'yadfa-items:gold-bar) (inventory-of (player-of *game*))))
                     (iter (for i from 0 to (random 5))
                       (push (make-instance 'yadfa-items:gem) (inventory-of (player-of *game*))))
                     (iter (for i from 0 to (random 5))
                       (push (make-instance 'yadfa-items:bandit-uniform-tunic) (inventory-of (player-of *game*))))
                     (iter (for i from 0 to (random 20))
                       (push (make-instance 'yadfa-items:bandit-adjustable-diaper) (inventory-of (player-of *game*))))
                     (push (make-instance 'yadfa-items:bandit-swimsuit/closed) (inventory-of (player-of *game*))))
                   (set-new-battle '((yadfa-enemies:diapered-raccoon-bandit . (list :level (random-from-range 2 5)
                                                                                    :bowels/contents 0
                                                                                    :wear (list
                                                                                           (make-instance 'yadfa-items:bandit-uniform-tunic)
                                                                                           (make-instance 'yadfa-items:bandit-adjustable-diaper
                                                                                            :messiness 8000))))))))
              ((< (random 12) 1)
               (set-new-battle '((yadfa-enemies:female-diapered-raccoon-bandit . (list :level (random-from-range 2 5))))))
              ((< (random 12) 1)
               (set-new-battle '((yadfa-enemies:rookie-diapered-raccoon-bandit . (list :level (random-from-range 2 5))))))
              ((< (random 12) 1)
               (set-new-battle '((yadfa-enemies:diapered-raccoon-bandit . (list :level (random-from-range 2 5))))))
              ((< (random 12) 1)
               (set-new-battle '((yadfa-enemies:giant-diapered-raccoon-bandit . (list :level (random-from-range 5)))))))))
(defevent obtain-diaper-lock-1
  :finished-depends '(enter-bandits-shop-1 get-diaper-locked-1)
  :predicate '(lambda (self)
               (declare (ignorable self))
               (and (lockedp (car (last (wear-of (player-of *game*))))) (>= (bitcoins-of (player-of *game*)) 10000)
                (or (> (bladder/contents-of (player-of *game*)) (* (bladder/maximum-limit-of (player-of *game*)) 5/6))
                 (> (bowels/contents-of (player-of *game*)) (* (bowels/maximum-limit-of (player-of *game*)) 5/6)))
                (and (< (getf (calculate-diaper-usage (player-of *game*)) :sogginess)
                      (/ (getf (calculate-diaper-usage (player-of *game*)) :sogginess-capacity) 4))
                 (< (getf (calculate-diaper-usage (player-of *game*)) :messiness)
                  (/ (getf (calculate-diaper-usage (player-of *game*)) :messiness-capacity) 4)))))
  :lambda '(lambda (self)
            (declare (ignorable self))
            (pushnew '(yadfa-items:magic-diaper-key . (list :value 10000))
             (yadfa-props:items-for-sale-of (getf (get-props-from-zone '(-3 22 0 yadfa-zones:bandits-domain)) :shop)))
            (format t "Shop owner: Seems you're stuck in a locked diaper. I can help.~%~%")
            (format t "~a: I'm listening~%~%" (name-of (player-of *game*)))
            (format t "I got one of those special artifacts that is used to lock and unlock these diapers. I can give it to you for 10000 bitcoins. Better pay up before you ~a yourself~%~%"
             (cond ((and (> (bladder/contents-of (player-of *game*)) (* (bladder/maximum-limit-of (player-of *game*)) 5/6))
                         (> (bowels/contents-of (player-of *game*)) (* (bowels/maximum-limit-of (player-of *game*)) 5/6)))
                    "flood and mess")
                   ((> (bladder/contents-of (player-of *game*)) (* (bladder/maximum-limit-of (player-of *game*)) 5/6))
                    "flood")
                   ((> (bowels/contents-of (player-of *game*)) (* (bowels/maximum-limit-of (player-of *game*)) 5/6))
                    "mess")))
            (format t "~a: Forget it!!! I don't need your help!!!~%~%" (name-of (player-of *game*)))
            (format t "*~a starts to waddle out the door, stops, then ~a*~%~%"
             (name-of (player-of *game*))
             (if (>
                  (bladder/contents-of (player-of *game*))
                  (* (bladder/maximum-limit-of (player-of *game*)) 5/6))
              (format nil "crosses ~a legs and clenches the front of ~a diaper"
               (if (malep (player-of *game*)) "his" "her")
               (if (malep (player-of *game*)) "his" "her"))
              (format nil "grabs the back of ~a diaper while clenching ~a butt cheeks"
               (if (malep (player-of *game*)) "his" "her")
               (if (malep (player-of *game*)) "his" "her"))))
            (format t "~a: On second thought, GIVE ME THAT KEY!!!!~%~%" (name-of (player-of *game*)))
            (format t "*~a pays up*~%~%" (name-of (player-of *game*)))
            (format t "Shop Owner: Thank you for your business, but before I hand you the key~%~%")
            (let ((a (cons (when (> (bladder/contents-of (player-of *game*)) (bladder/potty-dance-limit-of (player-of *game*)))
                             (wet))
                           (when (> (bowels/contents-of (player-of *game*)) (bowels/potty-dance-limit-of (player-of *game*)))
                             (mess)))))
              (cond ((and (car a) (cdr a))
                     (format t "*The raccoon puts on earplugs, then turns on the speakers in the room which starts playing the brown note, then starts tickling ~a~%~%" (name-of (player-of *game*)))
                     (format t "~a: ACK!!! NO!!! STOP!!!~%~%" (name-of (player-of *game*)))
                     (format t "*~a starts squirming and giggling then wets and messes ~a diapers*~%~%"
                             (name-of (player-of *game*))
                             (if (malep (player-of *game*)) "his" "her")))
                    ((car a)
                     (format t "*The raccoon starts tickling ~a~%~%"
                             (name-of (player-of *game*)))
                     (format t "~a: ACK!!! NO!!! STOP!!!~%~%" (name-of (player-of *game*)))
                     (format t "*~a starts squirming and giggling then wets ~a diapers*~%~%"
                             (name-of (player-of *game*))
                             (if (malep (player-of *game*)) "his" "her")))
                    ((cdr a)
                     (format t "*The raccoon puts on earplugs, then turns on the speakers in the room which starts playing the brown note~%~%")
                     (format t "*~a quickly grabs the back of ~a diapers before messing ~aself*~%~%"
                             (name-of (player-of *game*))
                             (if (malep (player-of *game*)) "his" "her")
                             (if (malep (player-of *game*)) "his" "her"))))
              (multiple-value-bind (value key)
                  (pop-from-expansion user a)
                (when (eq key :wet/mess)
                  (setf a value)))
              (format t "*The raccoon starts laughing*~%~%")
              (format t "Shop Owner: That never gets old. Here's the key as promised, enjoy ~abutt~%~%" (if (car a) "sog" "mush"))
              (when (cdr a)
                (format t "*The Rookie Raccoon waddles in*~%~%")
                (format t "Rookie Raccoon: I wish you wouldn't play that. You made me mess my diapers again~%~%")
                (format t "Shop Owner: Ha, you were gonna mess yourself anyway, so it's not like it matters.~%~%"))
              (format t "*After laughing his ass off, he suddenly stops and a soft hiss can be heard, the raccoon's face turns bright red and he quickly grabs the front of his diaper. The hissing continues for 10 seconds while everyone in the room stares at him while he floods his diapers.*~%~%")
              (format t "*~a lifts up the raccoon's tunic and squishes the front of his diaper*~%~%"
                      (name-of (player-of *game*)))
              (format t "~a: Seems you've had an accident too~%~%"
                      (name-of (player-of *game*)))
              (format t "Shop Owner: Shut up!!! *pulls his tunic back down while blushing bright red*~%~%"))))
(defevent enter-bandits-kennel-1
  :lambda '(lambda (self)
            (declare (ignorable self))
            (let ((a nil)
                  (b nil))
              (format t "*You enter the kennel and in 2 of the cages you see 2 orange foxes in heavily used diapers.*~%~%")
              (format t "Vixen: Hey! someone has entered the kennel for once!!!~%~%")
              (format t "Fox: Could you let us out? We're the town's 'pets' but they seemed to have forgotten about us.~%~%")
              (format t "Fox: and while you're at it, could you give us... umm... you know.... *blushes heavily*~%~%")
              (format t "~a: A diaper change?~%~%" (name-of (player-of *game*)))
              (format t "*the fox nods with a blush on his face*~%~%")
              (format t "~a: Fine, I'll be right back, don't go anywhere.~%~%" (name-of (player-of *game*)))
              (format t "*the 2 foxes sit down and waits, or in their case, crouches down and waits*~%~%")
              (format t "*as sitting in diapers in that state is out of the question~%~%")
              (format t "*~a enters the Bandit's shop, find a whimpering Rookie Raccoon in a toddler's dress and messy diaper being bounced on shop owner's knee*~%~%" (name-of (player-of *game*)))
              (format t " At least you now know why this shop carries Toddler dresses, while they're distracted*~%~%")
              (format t "*You grab a couple of adjustable diapers and a gold collar for the fox and a toddler's dress*~%~%")
              (format t "and a few of the much thicker diapers that the female raccoons wear for the vixen, you then head back to the kennel and dress the foxes and give them a diaper change*~%~%")
              (format t "~a: I'm back, and got you some new clothes~%~%" (name-of (player-of *game*)))
              (format t "Fox: Cool~%~%")
              (format t "Vixen: Yay~%~%")
              (format t "*the 2 wag their tails happily*~%~%")
              (format t "~a: Mind telling me your names?~%~%" (name-of (player-of *game*)))
              (finish-output)
              (accept-with-frame-resolved (clim:accepting-values (*query-io* :resynchronize-every-pass t :exit-boxes '((:exit "Accept")))
                                            (fresh-line *query-io*)
                                            (setf a (make-instance 'yadfa-allies:chris
                                                                   :name (clim:accept 'string
                                                                                      :prompt "Fox Name"
                                                                                      :default (second
                                                                                                (assoc :name (progn
                                                                                                               (c2mop:ensure-finalized
                                                                                                                (find-class 'yadfa-allies:chris))
                                                                                                               (c2mop:compute-default-initargs
                                                                                                                (find-class 'yadfa-allies:chris)))))
                                                                                      :view clim:+text-field-view+
                                                                                      :stream *query-io*)))
                                            (fresh-line *query-io*)
                                            (setf b (make-instance 'yadfa-allies:kristy
                                                                   :name (clim:accept 'string
                                                                                      :prompt "Vixen Name"
                                                                                      :default (second
                                                                                                (assoc :name (progn
                                                                                                               (c2mop:ensure-finalized
                                                                                                                (find-class 'yadfa-allies:kristy))
                                                                                                               (c2mop:compute-default-initargs
                                                                                                                (find-class 'yadfa-allies:kristy)))))
                                                                                      :view clim:+text-field-view+
                                                                                      :stream *query-io*)))))
              (iter (for i in (list a b))
                (do-push i (team-of *game*) (allies-of *game*)))
              (format t "Fox: I'm ~a~%~%" (name-of a))
              (format t "Vixen: And I'm ~a~%~%" (name-of b))
              (format t "~a: What's yours?~%~%" (name-of a))
              (format t "~a: I'm ~a. Now lets get you dressed~%~%" (name-of (player-of *game*)) (name-of (player-of *game*)))
              (format t "*~a puts the new clothes and diapers on the foxes*~%~%" (name-of a)))))
(defevent get-warp-pipe-summoner-1
  :finished-depends '(enter-bandits-shop-1 enter-bandits-kennel-1)
  :lambda '(lambda (self)
            (declare (ignorable self))
            (format t "*You enter the shop to find the whimpering Rookie still in a toddler's dress thrashing around and bouncing up and down in a baby bouncer*~%~%")
            (format t "Shop Owner: The baby decided to flood his diapers while I was giving him knee bounces, so I decided to reward him with happy bouncy fun time in the baby bouncer~%~%")
            (format t "Rookie: You wouldn't let me go and I couldn't hold it any longer!!!!~%~%")
            (format t "Shop Owner: A likely story. Anyway, before you go, I'd like to show you something. It's based on a dream the creator of this game had.~%~%")
            (format t "*The shop owner brings out a warp device and summons a warp pipe.*~%~%")
            (format t "Shop Owner: This warp pipe leads to the secret underground. In there is an infinite supply of several resources, a place where abdls can be themselves, and more warp pipes that let you warp just about anywhere in the game, though to avoid breaking the storyline, the creator of the game limited these warp pipes to the places you've already been~%~%")
            (format t "~a: Why are you giving me this?~%~%" (name-of (player-of *game*)))
            (format t "Shop Owner: Easy way to get back to this shop, so you can buy more crap from us.~%~%")
            (format t "~a: Ok *grabs the device and puts it in ~a inventory*~%~%" (name-of (player-of *game*)) (if (malep (player-of *game*)) "his" "her"))
            (push (make-instance 'yadfa-items:warp-device) (inventory-of (player-of *game*)))
            (setf (hiddenp (get-zone '(0 0 0 yadfa-zones:silver-cape))) nil)))
(defevent shopkeeper-floods-himself-1)
