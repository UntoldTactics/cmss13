// Snow, wood, sandbags, metal, plasteel

/obj/structure/barricade
	icon = 'icons/Marine/barricades.dmi'
	climbable = TRUE
	anchored = TRUE
	density = 1
	throwpass = TRUE //You can throw objects over this, despite its density.
	layer = BELOW_OBJ_LAYER
	flags_atom = ON_BORDER
	climb_delay = 20 //Leaping a barricade is universally much faster than clumsily climbing on a table or rack
	var/stack_type //The type of stack the barricade dropped when disassembled if any.
	var/stack_amount = 5 //The amount of stack dropped when disassembled at full health
	var/destroyed_stack_amount //to specify a non-zero amount of stack to drop when destroyed
	var/health = 100 //Pretty tough. Changes sprites at 300 and 150
	var/maxhealth = 100 //Basic code functions
	var/crusher_resistant = TRUE //Whether a crusher can ram through it.
	var/barricade_resistance = 5 //How much force an item needs to even damage it at all.
	var/barricade_hitsound

	var/barricade_type = "barricade" //"metal", "plasteel", etc.
	var/can_change_dmg_state = 1
	var/damage_state = 0
	var/closed = 0
	var/can_wire = 0
	var/is_wired = 0
	flags_barrier = HANDLE_BARRIER_CHANCE
	projectile_coverage = PROJECTILE_COVERAGE_HIGH

	New()
		..()
		spawn(0)
			update_icon()

/obj/structure/barricade/handle_barrier_chance(mob/living/M)
	return prob(max(30,(100.0*health)/maxhealth))

/obj/structure/barricade/examine(mob/user)
	..()

	if(is_wired)
		to_chat(user, "<span class='info'>There is a length of wire strewn across the top of this barricade.</span>")
	switch(damage_state)
		if(0) to_chat(user, "<span class='info'>It appears to be in good shape.</span>")
		if(1) to_chat(user, "<span class='warning'>It's slightly damaged, but still very functional.</span>")
		if(2) to_chat(user, "<span class='warning'>It's quite beat up, but it's holding together.</span>")
		if(3) to_chat(user, "<span class='warning'>It's crumbling apart, just a few more blows will tear it apart.</span>")

/obj/structure/barricade/hitby(atom/movable/AM)
	if(AM.throwing && is_wired)
		if(iscarbon(AM))
			var/mob/living/carbon/C = AM
			C.visible_message("<span class='danger'>The barbed wire slices into [C]!</span>",
			"<span class='danger'>The barbed wire slices into you!</span>")
			C.apply_damage(10)
			C.KnockDown(2) //Leaping into barbed wire is VERY bad
	..()



/obj/structure/barricade/Bumped(atom/A)
	..()

	if(istype(A, /mob/living/carbon/Xenomorph/Crusher))

		var/mob/living/carbon/Xenomorph/Crusher/C = A

		if(C.charge_speed < C.charge_speed_max/2)
			return

		if(crusher_resistant)
			take_damage( 100 )

		else if(!C.stat)
			visible_message("<span class='danger'>[C] smashes through [src]!</span>")
			destroy()

/obj/structure/barricade/CheckExit(atom/movable/O, turf/target)
	if(closed)
		return 1

	if(O.throwing)
		if(is_wired && iscarbon(O)) //Leaping mob against barbed wire fails
			if(get_dir(loc, target) & dir)
				return 0
		return 1

	if(get_dir(loc, target) & dir)
		return 0
	else
		return 1

/obj/structure/barricade/CanPass(atom/movable/mover, turf/target)
	if(closed)
		return 1

	if(mover && mover.throwing)
		if(is_wired && iscarbon(mover)) //Leaping mob against barbed wire fails
			if(get_dir(loc, target) & dir)
				return 0
		return 1

	var/obj/structure/S = locate(/obj/structure) in get_turf(mover)
	if(S && S.climbable && !(S.flags_atom & ON_BORDER) && climbable && isliving(mover)) //Climbable objects allow you to universally climb over others
		return 1

	if(get_dir(loc, target) & dir)
		return 0
	else
		return 1

/obj/structure/barricade/attack_robot(mob/user as mob)
	return attack_hand(user)

/obj/structure/barricade/attack_animal(mob/user as mob)
	return attack_alien(user)


/obj/structure/barricade/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/weapon/zombie_claws))
		user.visible_message("<span class='danger'>The zombie smashed at the [src.barricade_type] barricade!</span>",
		"<span class='danger'>You smack the [src.barricade_type] barricade!</span>")
		if(barricade_hitsound)
			playsound(src, barricade_hitsound, 25, 1)
		hit_barricade(W)
		return

	for(var/obj/effect/xenomorph/acid/A in src.loc)
		if(A.acid_t == src)
			to_chat(user, "You can't get near that, it's melting!")
			return

	if(istype(W, /obj/item/stack/barbed_wire))
		var/obj/item/stack/barbed_wire/B = W
		if(can_wire)
			user.visible_message("<span class='notice'>[user] starts setting up [W.name] on [src].</span>",
			"<span class='notice'>You start setting up [W.name] on [src].</span>")
			if(do_after(user, 20, TRUE, 5, BUSY_ICON_BUILD) && can_wire)
				playsound(src.loc, 'sound/effects/barbed_wire_movement.ogg', 25, 1)
				user.visible_message("<span class='notice'>[user] sets up [W.name] on [src].</span>",
				"<span class='notice'>You set up [W.name] on [src].</span>")
				B.use(1)
				update_icon()
				maxhealth += 50
				health += 50
				update_health()
				can_wire = 0
				is_wired = 1
				climbable = FALSE
		return

	if(istype(W, /obj/item/tool/wirecutters))
		if(is_wired)
			user.visible_message("<span class='notice'>[user] begin removing the barbed wire on [src].</span>",
			"<span class='notice'>You begin removing the barbed wire on [src].</span>")
			if(do_after(user, 20, TRUE, 5, BUSY_ICON_BUILD))
				playsound(src.loc, 'sound/items/Wirecutter.ogg', 25, 1)
				user.visible_message("<span class='notice'>[user] removes the barbed wire on [src].</span>",
				"<span class='notice'>You remove the barbed wire on [src].</span>")
				maxhealth -= 50
				health -= 50
				update_health()
				can_wire = 1
				is_wired = 0
				climbable = TRUE
				update_icon()
				new/obj/item/stack/barbed_wire( src.loc )
		return

	if(W.force > barricade_resistance)
		..()
		if(barricade_hitsound)
			playsound(src, barricade_hitsound, 25, 1)
		hit_barricade(W)

/obj/structure/barricade/destroy(deconstruct)
	if(deconstruct && is_wired)
		new /obj/item/stack/barbed_wire(loc)
	if(stack_type)
		var/stack_amt
		if(!deconstruct && destroyed_stack_amount) stack_amt = destroyed_stack_amount
		else stack_amt = round(stack_amount * (health/maxhealth)) //Get an amount of sheets back equivalent to remaining health. Obviously, fully destroyed means 0

		if(stack_amt) new stack_type (loc, stack_amt)
	qdel(src)


/obj/structure/barricade/ex_act(severity, direction)
	for(var/obj/structure/barricade/B in get_step(src,dir)) //discourage double-stacking barricades by removing health from opposing barricade
		if(B.dir == reverse_direction(dir))
			spawn(1)
			if(B)
				B.ex_act(severity, direction)
	health -= severity
	if(health <= 0)
		handle_debris(severity, direction)
		qdel(src)
	else
		update_health()

/obj/structure/barricade/get_explosion_resistance(direction)
	if(!density || direction == turn(dir, 90) || direction == turn(dir, -90))
		return 0
	else
		return min(health, 40)


/obj/structure/barricade/update_icon()
	overlays.Cut()
	if(!closed)
		if(can_change_dmg_state)
			icon_state = "[barricade_type]_[damage_state]"
		else
			icon_state = "[barricade_type]"
		switch(dir)
			if(SOUTH) layer = ABOVE_MOB_LAYER
			if(NORTH) layer = initial(layer) - 0.01
			else layer = initial(layer)
		if(!anchored)
			layer = initial(layer)
	else
		if(can_change_dmg_state)
			icon_state = "[barricade_type]_closed_[damage_state]"
		else
			icon_state = "[barricade_type]_closed"
		layer = OBJ_LAYER

	if(is_wired)
		if(!closed)
			overlays += image('icons/Marine/barricades.dmi', icon_state = "[src.barricade_type]_wire")
		else
			overlays += image('icons/Marine/barricades.dmi', icon_state = "[src.barricade_type]_closed_wire")

/obj/structure/barricade/proc/hit_barricade(obj/item/I)
	if(istype(I, /obj/item/weapon/zombie_claws))
		take_damage( I.force * 0.5 )
	take_damage( I.force * 0.5 )

obj/structure/barricade/proc/take_damage(var/damage)

	health -= damage

	for(var/obj/structure/barricade/B in get_step(src,dir)) //discourage double-stacking barricades by removing health from opposing barricade
		if(B.dir == reverse_direction(dir))
			B.health -= damage
			B.update_health()

	update_health()

/obj/structure/barricade/proc/update_health(nomessage)
	health = Clamp(health, 0, maxhealth)

	if(!health)
		if(!nomessage)
			visible_message("<span class='danger'>[src] falls apart!</span>")
		destroy()
		return

	update_damage_state()
	update_icon()

/obj/structure/barricade/proc/update_damage_state()
	var/health_percent = round(health/maxhealth * 100)
	switch(health_percent)
		if(0 to 25) damage_state = 3
		if(25 to 50) damage_state = 2
		if(50 to 75) damage_state = 1
		if(75 to INFINITY) damage_state = 0


/obj/structure/barricade/proc/acid_smoke_damage(var/obj/effect/particle_effect/smoke/S)
	take_damage( 15 )

/obj/structure/barricade/verb/rotate()
	set name = "Rotate Barricade Counter-Clockwise"
	set category = "Object"
	set src in oview(1)

	if(anchored)
		to_chat(usr, "<span class='warning'>It is fastened to the floor, you can't rotate it!</span>")
		return 0

	dir = turn(dir, 90)
	update_icon()
	return

/obj/structure/barricade/verb/revrotate()
	set name = "Rotate Barricade Clockwise"
	set category = "Object"
	set src in oview(1)

	if(anchored)
		to_chat(usr, "<span class='warning'>It is fastened to the floor, you can't rotate it!</span>")
		return 0

	dir = turn(dir, 270)
	update_icon()
	return


/*----------------------*/
// SNOW
/*----------------------*/

/obj/structure/barricade/snow
	name = "snow barricade"
	desc = "A mound of snow shaped into a sloped wall. Statistically better than thin air as cover."
	icon_state = "snow_0"
	barricade_type = "snow"
	health = 75 //Actual health depends on snow layer
	maxhealth = 75
	stack_type = /obj/item/stack/snow
	debris = list(/obj/item/stack/snow)
	stack_amount = 3
	destroyed_stack_amount = 0
	can_wire = 0

/obj/structure/barricade/snow/New(loc, direction)
	if(direction)
		dir = direction
	..()



//Item Attack
/obj/structure/barricade/snow/attackby(obj/item/W, mob/user)
	for(var/obj/effect/xenomorph/acid/A in src.loc)
		if(A.acid_t == src)
			to_chat(user, "You can't get near that, it's melting!")
			return
	//Removing the barricades
	if(istype(W, /obj/item/tool/shovel) && user.a_intent != "hurt")
		var/obj/item/tool/shovel/ET = W
		if(ET.folded)
			return
		if(user.action_busy)
			to_chat(user, "<span class='warning'>You are already shoveling!</span>")
			return
		user.visible_message("[user.name] starts clearing out \the [src].","You start removing \the [src].")
		if(!do_after(user, ET.shovelspeed, TRUE, 5, BUSY_ICON_BUILD))
			return
		if(!ET.folded)
			user.visible_message("<span class='notice'>\The [user] removes \the [src].</span>")
			destroy(TRUE)
		return
	else
		. = ..()

/obj/structure/barricade/snow/hit_barricade(obj/item/I)
	switch(I.damtype)
		if("fire")
			take_damage( I.force * 0.6 )
		if("brute")
			take_damage( I.force * 0.3 )

	return

/obj/structure/barricade/snow/bullet_act(var/obj/item/projectile/P)
	bullet_ping(P)
	take_damage( round(P.damage/2) ) //Not that durable.

	if (istype(P.ammo, /datum/ammo/xeno/boiler_gas))
		take_damage( 50 )

	return 1

/*----------------------*/
// WOOD
/*----------------------*/

/obj/structure/barricade/wooden
	name = "wooden barricade"
	desc = "A wall made out of wooden planks nailed together. Not very sturdy, but can provide some concealment."
	icon_state = "wooden"
	health = 100
	maxhealth = 100
	layer = OBJ_LAYER
	stack_type = /obj/item/stack/sheet/wood
	debris = list(/obj/item/stack/sheet/wood)
	stack_amount = 5
	destroyed_stack_amount = 3
	barricade_hitsound = "sound/effects/woodhit.ogg"
	can_change_dmg_state = 0
	barricade_type = "wooden"
	can_wire = 0

/obj/structure/barricade/wooden/attackby(obj/item/W as obj, mob/user as mob)
	for(var/obj/effect/xenomorph/acid/A in src.loc)
		if(A.acid_t == src)
			to_chat(user, "You can't get near that, it's melting!")
			return
	if(istype(W, /obj/item/stack/sheet/wood))
		var/obj/item/stack/sheet/wood/D = W
		if(health < maxhealth)
			if(D.get_amount() < 1)
				to_chat(user, "<span class='warning'>You need one plank of wood to repair [src].</span>")
				return
			visible_message("<span class='notice'>[user] begins to repair [src].</span>")
			if(do_after(user,20, TRUE, 5, BUSY_ICON_FRIENDLY) && health < maxhealth)
				if (D.use(1))
					health = maxhealth
					visible_message("<span class='notice'>[user] repairs [src].</span>")
		return
	. = ..()

/obj/structure/barricade/wooden/hit_barricade(obj/item/I)
	switch(I.damtype)
		if("fire")
			take_damage( I.force * 1.5 )
		if("brute")
			take_damage( I.force * 0.75 )

/obj/structure/barricade/wooden/bullet_act(var/obj/item/projectile/P)
	bullet_ping(P)
	take_damage( round(P.damage/2) ) //Not that durable.

	if(istype(P.ammo, /datum/ammo/xeno/boiler_gas))
		take_damage( 50 )

	return 1

/*----------------------*/
// METAL
/*----------------------*/

/obj/structure/barricade/metal
	name = "metal barricade"
	desc = "A sturdy and easily assembled barricade made of metal plates, often used for quick fortifications. Use a blowtorch to repair."
	icon_state = "metal_0"
	health = 275
	maxhealth = 275
	crusher_resistant = TRUE
	barricade_resistance = 10
	stack_type = /obj/item/stack/sheet/metal
	debris = list(/obj/item/stack/sheet/metal)
	stack_amount = 4
	destroyed_stack_amount = 2
	barricade_hitsound = "sound/effects/metalhit.ogg"
	barricade_type = "metal"
	can_wire = 1
	var/build_state = 2 //2 is fully secured, 1 is after screw, 0 is after wrench. Crowbar disassembles

/obj/structure/barricade/metal/examine(mob/user)
	..()
	switch(build_state)
		if(2)
			to_chat(user, "<span class='info'>The protection panel is still tighly screwed in place.</span>")
		if(1)
			to_chat(user, "<span class='info'>The protection panel has been removed, you can see the anchor bolts.</span>")
		if(0)
			to_chat(user, "<span class='info'>The protection panel has been removed and the anchor bolts loosened. It's ready to be taken apart.</span>")

/obj/structure/barricade/metal/attackby(obj/item/W, mob/user)

	for(var/obj/effect/xenomorph/acid/A in src.loc)
		if(A.acid_t == src)
			to_chat(user, "You can't get near that, it's melting!")
			return

	if(iswelder(W))
		if(user.action_busy)
			return
		if(user.mind && user.mind.cm_skills && user.mind.cm_skills.engineer < SKILL_ENGINEER_METAL)
			to_chat(user, "<span class='warning'>You're not trained to repair [src]...</span>")
			return
		var/obj/item/tool/weldingtool/WT = W
		if(health <= maxhealth * 0.3)
			to_chat(user, "<span class='warning'>[src] has sustained too much structural damage to be repaired.</span>")
			return

		if(health == maxhealth)
			to_chat(user, "<span class='warning'>[src] doesn't need repairs.</span>")
			return

		var/old_loc = loc

		if(WT.remove_fuel(0, user))
			user.visible_message("<span class='notice'>[user] begins repairing damage to [src].</span>",
			"<span class='notice'>You begin repairing the damage to [src].</span>")
			playsound(src.loc, 'sound/items/Welder2.ogg', 25, 1)
			if(do_after(user, 50, TRUE, 5, BUSY_ICON_FRIENDLY) && old_loc == loc)
				user.visible_message("<span class='notice'>[user] repairs some damage on [src].</span>",
				"<span class='notice'>You repair [src].</span>")
				health += 150
				update_health()
				playsound(src.loc, 'sound/items/Welder2.ogg', 25, 1)
		return

	switch(build_state)
		if(2) //Fully constructed step. Use screwdriver to remove the protection panels to reveal the bolts
			if(isscrewdriver(W))
				if(user.action_busy)
					return
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.construction < SKILL_CONSTRUCTION_METAL)
					to_chat(user, "<span class='warning'>You are not trained to disassemble [src]...</span>")
					return
				playsound(src.loc, 'sound/items/Screwdriver.ogg', 25, 1)
				if(!do_after(user, 10, TRUE, 5, BUSY_ICON_BUILD)) return
				user.visible_message("<span class='notice'>[user] removes [src]'s protection panel.</span>",
				"<span class='notice'>You remove [src]'s protection panels, exposing the anchor bolts.</span>")
				build_state = 1
				return
		if(1) //Protection panel removed step. Screwdriver to put the panel back, wrench to unsecure the anchor bolts
			if(isscrewdriver(W))
				if(user.action_busy)
					return
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.construction < SKILL_CONSTRUCTION_METAL)
					to_chat(user, "<span class='warning'>You are not trained to assemble [src]...</span>")
					return
				playsound(src.loc, 'sound/items/Screwdriver.ogg', 25, 1)
				if(!do_after(user, 10, TRUE, 5, BUSY_ICON_BUILD)) return
				user.visible_message("<span class='notice'>[user] set [src]'s protection panel back.</span>",
				"<span class='notice'>You set [src]'s protection panel back.</span>")
				build_state = 2
				return
			if(iswrench(W))
				if(user.action_busy)
					return
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.construction < SKILL_CONSTRUCTION_METAL)
					to_chat(user, "<span class='warning'>You are not trained to disassemble [src]...</span>")
					return
				playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
				if(!do_after(user, 10, TRUE, 5, BUSY_ICON_BUILD)) return
				user.visible_message("<span class='notice'>[user] loosens [src]'s anchor bolts.</span>",
				"<span class='notice'>You loosen [src]'s anchor bolts.</span>")
				anchored = FALSE
				build_state = 0
				update_icon() //unanchored changes layer
				return
		if(0) //Anchor bolts loosened step. Apply crowbar to unseat the panel and take apart the whole thing. Apply wrench to resecure anchor bolts
			if(iswrench(W))
				if(user.action_busy)
					return
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.construction < SKILL_CONSTRUCTION_METAL)
					to_chat(user, "<span class='warning'>You are not trained to assemble [src]...</span>")
					return
				for(var/obj/structure/barricade/B in loc)
					if(B != src && B.dir == dir)
						to_chat(user, "<span class='warning'>There's already a barricade here.</span>")
						return
				playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
				if(!do_after(user, 10, TRUE, 5, BUSY_ICON_BUILD)) return
				user.visible_message("<span class='notice'>[user] secures [src]'s anchor bolts.</span>",
				"<span class='notice'>You secure [src]'s anchor bolts.</span>")
				build_state = 1
				anchored = TRUE
				update_icon() //unanchored changes layer
				return
			if(iscrowbar(W))
				if(user.action_busy)
					return
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.construction < SKILL_CONSTRUCTION_METAL)
					to_chat(user, "<span class='warning'>You are not trained to disassemble [src]...</span>")
					return
				user.visible_message("<span class='notice'>[user] starts unseating [src]'s panels.</span>",
				"<span class='notice'>You start unseating [src]'s panels.</span>")
				playsound(src.loc, 'sound/items/Crowbar.ogg', 25, 1)
				if(do_after(user, 50, TRUE, 5, BUSY_ICON_BUILD))
					user.visible_message("<span class='notice'>[user] takes [src]'s panels apart.</span>",
					"<span class='notice'>You take [src]'s panels apart.</span>")
					playsound(loc, 'sound/items/Deconstruct.ogg', 25, 1)
					destroy(TRUE) //Note : Handles deconstruction too !
				return

	. = ..()

/obj/structure/barricade/metal/bullet_act(obj/item/projectile/P)
	bullet_ping(P)
	take_damage( round(P.damage/10) )

	if(istype(P.ammo, /datum/ammo/xeno/boiler_gas))
		take_damage( 50 )

	return 1

/*----------------------*/
// DEPLOYABLE
/*----------------------*/

/obj/structure/barricade/deployable
	name = "portable composite barricade"
	desc = "A plasteel-carbon composite barricade. Resistant to most acids while being simple to repair. There are two pushplates that allow this barricade to fold into a neat package. Use a blowtorch to repair."
	icon_state = "folding_0"
	health = 400
	maxhealth = 400
	crusher_resistant = TRUE
	barricade_resistance = 15
	barricade_hitsound = "sound/effects/metalhit.ogg"
	barricade_type = "folding"
	can_wire = 0
	can_change_dmg_state = 1
	climbable = FALSE
	unacidable = 1
	anchored = TRUE

/obj/structure/barricade/deployable/examine(mob/user)
	..()
	to_chat(user, "<span class='info'>Drag its sprite onto yourself to undeploy.</span>")

/obj/structure/barricade/deployable/attackby(obj/item/W, mob/user)

	if(iswelder(W))
		if(user.action_busy)
			return
		var/obj/item/tool/weldingtool/WT = W
		if(health == maxhealth)
			to_chat(user, "<span class='warning'>[src] doesn't need repairs.</span>")
			return

		var/old_loc = loc

		if(WT.remove_fuel(0, user))
			user.visible_message("<span class='notice'>[user] begins repairing damage to [src].</span>",
			"<span class='notice'>You begin repairing the damage to [src].</span>")
			playsound(src.loc, 'sound/items/Welder2.ogg', 25, 1)
			if(do_after(user, 50, TRUE, 5, BUSY_ICON_FRIENDLY) && old_loc == loc)
				user.visible_message("<span class='notice'>[user] repairs some damage on [src].</span>",
				"<span class='notice'>You repair [src].</span>")
				health += maxhealth*0.4
				if(health < maxhealth)
					maxhealth -= 50
					user.visible_message("<span class='notice'>[src]'s structural integrity weakens.</span>")

				update_health()
				playsound(src.loc, 'sound/items/Welder2.ogg', 25, 1)
		return

	. = ..()

/obj/structure/barricade/deployable/MouseDrop(obj/over_object as obj)
	if(!ishuman(usr))
		return

	if(usr.lying)
		return

	if(over_object == usr && Adjacent(usr))
		collapse(usr)

/obj/structure/barricade/deployable/proc/collapse(mob/living/carbon/human/user)
	if(!istype(user))
		return
	user.visible_message("<span class='notice'>[user] starts collapsing [src].</span>",
			"<span class='notice'>You begin collapsing [src].</span>")
	playsound(src.loc, 'sound/items/Crowbar.ogg', 25, 1)
	var/old_loc = loc
	if(do_after(user, 80, TRUE, 5, BUSY_ICON_FRIENDLY) && old_loc == loc)
		var/obj/item/folding_barricade/f = new(loc)
		f.health = health
		f.maxhealth = maxhealth
		user.put_in_active_hand(f)
		qdel(src)

/obj/structure/barricade/deployable/bullet_act(obj/item/projectile/P)
	bullet_ping(P)
	take_damage( round(P.damage/10) )

	if(istype(P.ammo, /datum/ammo/xeno/boiler_gas))
		take_damage( 50 )

	return 1

//CADE IN HANDS
/obj/item/folding_barricade
	name = "MB-6 Folding Barricade"
	desc = "A folding barricade that can be used to quickly deploy an all-round resistant barricade."
	health = 400
	var/maxhealth = 400
	w_class = 4
	flags_equip_slot = SLOT_BACK
	icon_state = "folding"
	icon = 'icons/Marine/marine-items.dmi'

/obj/item/folding_barricade/attack_self(mob/user as mob)
	for(var/obj/structure/barricade/B in loc)
		if(B != src && B.dir == dir)
			to_chat(user, "<span class='warning'>There's already a barricade here.</span>")
			return
	user.visible_message("<span class='notice'>[user] begins deploying [src].</span>",
			"<span class='notice'>You begin deploying [src].</span>")
	playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
	if(!do_after(user, 10, TRUE, 5, BUSY_ICON_BUILD)) return
	user.visible_message("<span class='notice'>[user] has finished deploying [src].</span>",
			"<span class='notice'>You finish deploying [src].</span>")
	var/obj/structure/barricade/deployable/cade = new(user.loc)
	cade.dir = user.dir
	cade.health = health
	cade.maxhealth = maxhealth
	qdel(src)

/*----------------------*/
// PLASTEEL
/*----------------------*/

/obj/structure/barricade/plasteel
	name = "plasteel barricade"
	desc = "A very sturdy barricade made out of plasteel panels, the pinnacle of strongpoints. Use a blowtorch to repair. Can be flipped down to create a path."
	icon_state = "plasteel_closed_0"
	health = 600
	maxhealth = 600
	crusher_resistant = TRUE
	barricade_resistance = 20
	stack_type = /obj/item/stack/sheet/plasteel
	debris = list(/obj/item/stack/sheet/plasteel)
	stack_amount = 5
	destroyed_stack_amount = 2
	barricade_hitsound = "sound/effects/metalhit.ogg"
	barricade_type = "plasteel"
	density = 0
	closed = 1
	can_wire = 1

	var/build_state = 2 //2 is fully secured, 1 is after screw, 0 is after wrench. Crowbar disassembles
	var/tool_cooldown = 0 //Delay to apply tools to prevent spamming
	var/busy = 0 //Standard busy check
	var/linked = 0
	var/recentlyflipped = FALSE

/obj/structure/barricade/plasteel/update_icon()
	..()
	if(linked)
		for(var/direction in cardinal)
			for(var/obj/structure/barricade/plasteel/cade in get_step(src, direction))
				if(((dir & (NORTH|SOUTH) && get_dir(src, cade) & (EAST|WEST)) || (dir & (EAST|WEST) && get_dir(src, cade) & (NORTH|SOUTH))) && dir == cade.dir && cade.linked && cade.closed == src.closed)
					if(closed)
						overlays += image('icons/Marine/barricades.dmi', icon_state = "[src.barricade_type]_closed_connection_[get_dir(src, cade)]")
					else
						overlays += image('icons/Marine/barricades.dmi', icon_state = "[src.barricade_type]_connection_[get_dir(src, cade)]")
					continue


/obj/structure/barricade/plasteel/handle_barrier_chance(mob/living/M)
	if(closed)
		return ..()
	else
		return 0

/obj/structure/barricade/plasteel/examine(mob/user)
	..()

	switch(build_state)
		if(2)
			to_chat(user, "<span class='info'>The protection panel is still tighly screwed in place.</span>")
		if(1)
			to_chat(user, "<span class='info'>The protection panel has been removed, you can see the anchor bolts.</span>")
		if(0)
			to_chat(user, "<span class='info'>The protection panel has been removed and the anchor bolts loosened. It's ready to be taken apart.</span>")

/obj/structure/barricade/plasteel/attackby(obj/item/W, mob/user)
	for(var/obj/effect/xenomorph/acid/A in src.loc)
		if(A.acid_t == src)
			to_chat(user, "You can't get near that, it's melting!")
			return

	if(iswelder(W))
		if(busy || tool_cooldown > world.time)
			return
		tool_cooldown = world.time + 10
		if(user.mind && user.mind.cm_skills && user.mind.cm_skills.engineer < SKILL_ENGINEER_PLASTEEL)
			to_chat(user, "<span class='warning'>You're not trained to repair [src]...</span>")
			return
		var/obj/item/tool/weldingtool/WT = W
		if(health <= maxhealth * 0.3)
			to_chat(user, "<span class='warning'>[src] has sustained too much structural damage to be repaired.</span>")
			return

		if(health == maxhealth)
			to_chat(user, "<span class='warning'>[src] doesn't need repairs.</span>")
			return

		if(WT.remove_fuel(0, user))
			user.visible_message("<span class='notice'>[user] begins repairing damage to [src].</span>",
			"<span class='notice'>You begin repairing the damage to [src].</span>")
			playsound(src.loc, 'sound/items/Welder2.ogg', 25, 1)
			busy = 1
			if(do_after(user, 50, TRUE, 5, BUSY_ICON_FRIENDLY))
				busy = 0
				user.visible_message("<span class='notice'>[user] repairs some damage on [src].</span>",
				"<span class='notice'>You repair [src].</span>")
				health += 150
				update_health()
				playsound(src.loc, 'sound/items/Welder2.ogg', 25, 1)
			else busy = 0
		return

	switch(build_state)
		if(2) //Fully constructed step. Use screwdriver to remove the protection panels to reveal the bolts
			if(isscrewdriver(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.engineer < SKILL_ENGINEER_PLASTEEL)
					to_chat(user, "<span class='warning'>You are not trained to assemble [src]...</span>")
					return

				for(var/obj/structure/barricade/B in loc)
					if(B != src && B.dir == dir)
						to_chat(user, "<span class='warning'>There's already a barricade here.</span>")
						return
				user.visible_message("<span class='notice'>[user] removes [src]'s protection panel.</span>",

				"<span class='notice'>You remove [src]'s protection panels, exposing the anchor bolts.</span>")
				playsound(src.loc, 'sound/items/Screwdriver.ogg', 25, 1)
				build_state = 1
				return
			if(iscrowbar(W))
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.engineer < SKILL_ENGINEER_PLASTEEL)
					to_chat(user, "<span class='warning'>You are not trained to modify [src]...</span>")
					return
				playsound(src.loc, 'sound/items/Crowbar.ogg', 25, 1)
				if(linked)
					user.visible_message("<span class='notice'>[user] removes the linking on [src].</span>",
					"<span class='notice'>You remove the linking on [src].</span>")
				else
					user.visible_message("<span class='notice'>[user] sets up [src] for linking.</span>",
					"<span class='notice'>You set up [src] for linking.</span>")
				linked = !linked
				for(var/direction in cardinal)
					for(var/obj/structure/barricade/plasteel/cade in get_step(src, direction))
						cade.update_icon()
				update_icon()
		if(1) //Protection panel removed step. Screwdriver to put the panel back, wrench to unsecure the anchor bolts
			if(isscrewdriver(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.engineer < SKILL_ENGINEER_PLASTEEL)
					to_chat(user, "<span class='warning'>You are not trained to assemble [src]...</span>")
					return
				user.visible_message("<span class='notice'>[user] set [src]'s protection panel back.</span>",
				"<span class='notice'>You set [src]'s protection panel back.</span>")
				playsound(src.loc, 'sound/items/Screwdriver.ogg', 25, 1)
				build_state = 2
				return
			if(iswrench(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.engineer < SKILL_ENGINEER_PLASTEEL)
					to_chat(user, "<span class='warning'>You are not trained to assemble [src]...</span>")
					return
				user.visible_message("<span class='notice'>[user] loosens [src]'s anchor bolts.</span>",
				"<span class='notice'>You loosen [src]'s anchor bolts.</span>")
				playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
				anchored = FALSE
				build_state = 0
				update_icon() //unanchored changes layer
				return

		if(0) //Anchor bolts loosened step. Apply crowbar to unseat the panel and take apart the whole thing. Apply wrench to rescure anchor bolts
			if(iswrench(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.engineer < SKILL_ENGINEER_PLASTEEL)
					to_chat(user, "<span class='warning'>You are not trained to assemble [src]...</span>")
					return
				user.visible_message("<span class='notice'>[user] secures [src]'s anchor bolts.</span>",
				"<span class='notice'>You secure [src]'s anchor bolts.</span>")
				playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
				anchored = TRUE
				build_state = 1
				update_icon() //unanchored changes layer
				return
			if(iscrowbar(W))
				if(busy || tool_cooldown > world.time)
					return
				tool_cooldown = world.time + 10
				if(user.mind && user.mind.cm_skills && user.mind.cm_skills.engineer < SKILL_ENGINEER_PLASTEEL)
					to_chat(user, "<span class='warning'>You are not trained to assemble [src]...</span>")
					return
				user.visible_message("<span class='notice'>[user] starts unseating [src]'s panels.</span>",
				"<span class='notice'>You start unseating [src]'s panels.</span>")
				playsound(src.loc, 'sound/items/Crowbar.ogg', 25, 1)
				busy = 1
				if(do_after(user, 50, TRUE, 5, BUSY_ICON_BUILD))
					busy = 0
					user.visible_message("<span class='notice'>[user] takes [src]'s panels apart.</span>",
					"<span class='notice'>You take [src]'s panels apart.</span>")
					playsound(loc, 'sound/items/Deconstruct.ogg', 25, 1)
					destroy(TRUE) //Note : Handles deconstruction too !
				else busy = 0
				return

	. = ..()

/obj/structure/barricade/plasteel/attack_hand(mob/user as mob)
	if(isXeno(user))
		return

	if(closed)
		if(recentlyflipped)
			to_chat(user, "<span class='notice'>The [src] has been flipped too recently!</span>")
			return
		user.visible_message("<span class='notice'>[user] flips [src] open.</span>",
		"<span class='notice'>You flip [src] open.</span>")
		open(src)
		recentlyflipped = TRUE
		spawn(10)
			if(istype(src, /obj/structure/barricade/plasteel))
				recentlyflipped = FALSE

	else
		if(recentlyflipped)
			to_chat(user, "<span class='notice'>The [src] has been flipped too recently!</span>")
			return
		user.visible_message("<span class='notice'>[user] flips [src] closed.</span>",
		"<span class='notice'>You flip [src] closed.</span>")
		close(src)
		recentlyflipped = TRUE
		spawn(10)
			if(istype(src, /obj/structure/barricade/plasteel))
				recentlyflipped = FALSE

/obj/structure/barricade/plasteel/proc/open(var/obj/structure/barricade/plasteel/origin)
	if(!closed)
		return
	playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
	closed = 0
	density = 0
	if(linked)
		for(var/direction in cardinal)
			for(var/obj/structure/barricade/plasteel/cade in get_step(src, direction))
				if(((dir & (NORTH|SOUTH) && get_dir(src, cade) & (EAST|WEST)) || (dir & (EAST|WEST) && get_dir(src, cade) & (NORTH|SOUTH))) && dir == cade.dir && cade != origin && cade.linked)
					cade.open(src)
	update_icon()

/obj/structure/barricade/plasteel/proc/close(var/obj/structure/barricade/plasteel/origin)
	if(closed)
		return
	playsound(src.loc, 'sound/items/Ratchet.ogg', 25, 1)
	closed = 1
	density = 1
	if(linked)
		for(var/direction in cardinal)
			for(var/obj/structure/barricade/plasteel/cade in get_step(src, direction))
				if(((dir & (NORTH|SOUTH) && get_dir(src, cade) & (EAST|WEST)) || (dir & (EAST|WEST) && get_dir(src, cade) & (NORTH|SOUTH))) && dir == cade.dir && cade != origin && cade.linked)
					cade.close(src)
	update_icon()

/obj/structure/barricade/plasteel/bullet_act(obj/item/projectile/P)
	bullet_ping(P)
	take_damage( round(P.damage/10) )

	if(istype(P.ammo, /datum/ammo/xeno/boiler_gas))
		take_damage( 50 )

	return 1

/*----------------------*/
// SANDBAGS
/*----------------------*/

/obj/structure/barricade/sandbags
	name = "sandbag barricade"
	desc = "A bunch of bags filled with sand, stacked into a small wall. Surprisingly sturdy, albeit labour intensive to set up. Trusted to do the job since 1914."
	icon_state = "sandbag_0"
	barricade_resistance = 15
	health = 400
	maxhealth = 400
	stack_type = /obj/item/stack/sandbags
	debris = list(/obj/item/stack/sandbags, /obj/item/stack/sandbags)
	barricade_hitsound = "sound/weapons/Genhit.ogg"
	barricade_type = "sandbag"
	can_wire = 1

/obj/structure/barricade/sandbags/New(loc, direction)
	if(direction)
		dir = direction

	if(dir == SOUTH)
		pixel_y = -7
	else if(dir == NORTH)
		pixel_y = 7
	..()


/obj/structure/barricade/sandbags/attackby(obj/item/W, mob/user)

	for(var/obj/effect/xenomorph/acid/A in src.loc)
		if(A.acid_t == src)
			to_chat(user, "You can't get near that, it's melting!")
			return

	if(istype(W, /obj/item/tool/shovel) && user.a_intent != "hurt")
		var/obj/item/tool/shovel/ET = W
		if(!ET.folded)
			user.visible_message("<span class='notice'>[user] starts disassembling [src].</span>",
			"<span class='notice'>You start disassembling [src].</span>")
			if(do_after(user, ET.shovelspeed, TRUE, 5, BUSY_ICON_BUILD))
				user.visible_message("<span class='notice'>[user] disassembles [src].</span>",
				"<span class='notice'>You disassemble [src].</span>")
				destroy(TRUE)
		return 1
	else
		. = ..()

/obj/structure/barricade/sandbags/bullet_act(obj/item/projectile/P)
	bullet_ping(P)
	take_damage( round(P.damage/10) )

	if(istype(P.ammo, /datum/ammo/xeno/boiler_gas))
		take_damage( 50 )

	return 1

/obj/structure/barricade/sandbags/wired/New()
	maxhealth += 50
	health += 50
	update_health()
	can_wire = 0
	is_wired = 1
	update_icon()
	climbable = FALSE
	. = ..()


/obj/structure/barricade/plasteel/wired/New()
	maxhealth += 50
	health += 50
	update_health()
	can_wire = 0
	is_wired = 1
	climbable = FALSE
	update_icon()
	. = ..()
/obj/structure/barricade/metal/wired/New()
	maxhealth += 50
	health += 50
	update_health()
	can_wire = 0
	is_wired = 1
	climbable = FALSE
	update_icon()
	. = ..()