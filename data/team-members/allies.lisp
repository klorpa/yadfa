;;;; -*- mode: Common-Lisp; sly-buffer-package: "yadfa-allies"; coding: utf-8-unix; -*-
(in-package :yadfa-allies)
(defclass slynk (playable-ally ally-last-minute-potty-training pantsable-character) ()
  (:default-initargs
   :name "Slynk"
   :male t
   :wear (let ((diaper (progn (c2mop:ensure-finalized (find-class 'yadfa-items:bandit-adjustable-diaper))
                              (c2mop:compute-default-initargs (find-class 'yadfa-items:bandit-adjustable-diaper)))))
           (list (make-instance 'yadfa-items:bandit-uniform-tunic)
                 (make-instance 'yadfa-items:thick-rubber-diaper)
                 (make-instance 'yadfa-items:bandit-adjustable-diaper
                                :sogginess (second (assoc :sogginess-capacity diaper))
                                :messiness (second (assoc :messiness-capacity diaper)))))
   :species "Raccoon"
   :tail-type :medium
   :tail '(:fur)
   :skin '(:fur)
   :description "Used to be one of the Diapered Raccoon Bandits. Was kicked out after he was forced to give the location of Pirate's Cove to the Navy. He was humiliated constantly by the Diapered Pirates until you rescued him. Is too embarrassed to admit when he as to go unless he's desperate"
   :level 5))
(defmethod initialize-instance :after
    ((c slynk) &rest args &key &allow-other-keys)
  (unless (iter (for (a b) on args)
            (when (eq a :bladder/contents)
              (leave t)))
    (setf (bladder/contents-of c)
          (random (coerce (+ (bladder/potty-desperate-limit-of c) (/ (- (bladder/potty-desperate-limit-of c) (bladder/potty-dance-limit-of c)))) 'long-float))))
  (unless (iter (for (a b) on args)
            (when (eq a :bowels/contents)
              (leave t)))
    (setf (bowels/contents-of c)
          (random (coerce (+ (bowels/potty-desperate-limit-of c) (/ (- (bowels/potty-desperate-limit-of c) (bowels/potty-dance-limit-of c)))) 'long-float)))))
(defclass chris (playable-ally ally-rebel-potty-training) ()
  (:default-initargs
   :name "Chris"
   :male t
   :species "Fox"
   :tail-type :medium
   :tail '(:fur)
   :skin '(:fur)
   :description "An orange fox. has gotten accustomed to being treated like a pet and will typically wear nothing but a collar, refuses to be housebroken like a good fox so he must be diapered at all times."
   :wear (list (make-instance 'yadfa-items:gold-collar)
               (make-instance 'yadfa-items:bandit-diaper))))
(defclass kristy (playable-ally ally-no-potty-training pantsable-character) ()
  (:default-initargs
   :name "Kristy"
   :male nil
   :species "Fox"
   :tail-type :medium
   :tail '(:fur)
   :skin '(:fur)
   :description "A beautiful orange vixen who has a personality that is more like a child than an adult. Loves wearing thick diapers, can't stand pants. Has gone without diapers for so long that she has become dependent on them."
   :wear (list (make-instance 'yadfa-items:toddler-dress)
               (make-instance 'yadfa-items:bandit-female-diaper))))
(defclass furry (playable-ally ally-silent-potty-training pantsable-character) ()
  (:default-initargs
   :name "Furry"
   :male t
   :species "Fox"
   :tail-type :medium
   :tail '(:fur)
   :skin '(:fur)
   :description "A fox that likes to wear a fursuit. Doesn't talk much. The team got him as a pet, and as a plushie."
   :wear (list (make-instance 'yadfa-items:watertight-fursuit)
               (make-instance 'yadfa-items:kurikia-thick-cloth-diaper))))
