extends Node2D

enum {PATROL, SEARCH, SHADOW, ENGAGE, DISENGAGE, REPAIR}
var strategicPlan = {"fleetObject": PATROL}

# When fleet reaches previously set orders, request is sent here
func requestOrder(fleet, detection: Array, contactLost: Array):
	if strategicPlan[fleet] == PATROL:
		pass # Make decision according to strategic factors as to whether to change
	if strategicPlan[fleet] == SEARCH:
		pass # If detection occured, decide whether to shadow or engage
		# If detection did not occur, decide to patrol or continue searching
	if strategicPlan[fleet] == SHADOW:
		pass # If new ship detected (or lost contact), this request for new orders is received
	if strategicPlan[fleet] == ENGAGE:
		pass # Will receive this request type when threshold damage taken
		# Or sufficiently threatening new formation detected/lost contact with enemy fleet
	if strategicPlan[fleet] == DISENGAGE:
		pass # When lost contact with enemy fleet consider returning to patrol, continue disengaging
		# Or return to harbour to repair if threshold damage taken
