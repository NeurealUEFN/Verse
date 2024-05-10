using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /Fortnite.com/Characters }

##Simple Custom Indicator Device##
# NOTE: The main reason to do this is because the default indicator is buggy as of 05/09
#       There are plenty of cases where it will stop working in multiplayer and joining in progress 
#       This implementation however will not break and is battle tested. Hopefully future fixes to the default device renders this moot. 
 

## SET UP ## 
# 1. Setup the map with the map indicator device wherever you want
# the custom prop to appear. 
# 2. Once the map indicators are setup, assign them to the indicator_positions 
# array according to the order in which they should activate. The order of 
# assigning them in the array is important
# 3. Call update indicator to keep pushing the indicator to the next location, 
# after the last position it will automatically delete
# 4. Call end indicator to abruptly end the indicator from going forward and 
# deleting it
# 5. You can assign triggers to update_trigger and end_trigger, and use uefn
# events system to manipulate the indicator too
# 6. You can also change the duration in which the custom prop will move to the
# next location
# 7. Every indicator sequence requires an indicator_manager

indicator_manager<public>:=class(creative_device):

    @editable indicator_positions : []map_indicator_device := array{} # array that holds all the map indicator (positions) devices
    @editable indicator_prop : creative_prop_asset := DefaultCreativePropAsset # prop that will be spawned and act like indicator (You need to create a building prop and assign it to this variable)
    @editable update_trigger : trigger_device := trigger_device{} # trigger that holds the trigger_device to update the position of the current indicator
    @editable end_trigger : trigger_device := trigger_device{} # trigger that holds the trigger_device to end the current indicator
    @editable indicator_move_duration : float := 0.1 # duration required to move the indicator to the next location
    var CurrentIndex : int := 0
    var IsSpawnedIndicator : ?creative_prop := false

    ##Bind the triggers for using the direct event system of UEFN
    OnBegin<override>():void=
        {
            update_trigger.TriggeredEvent.Subscribe(Update_Indicator)
            end_trigger.TriggeredEvent.Subscribe(End_Indicator)
        }

    ##Move indicator to next spot. Argument should be false if called from code
    Update_Indicator<public>(Agent : ?agent):void=
        {
            if(CurrentIndex = 0, FirstIndicator := indicator_positions[CurrentIndex]):
                SpawnedIndicatorResult := SpawnProp(indicator_prop, FirstIndicator.GetTransform())
                set IsSpawnedIndicator = SpawnedIndicatorResult(0)
            else:
                set CurrentIndex += 1
                spawn{MoveIndicator()}            
        }

    ##End indicator and dispose the prop. Argument should be false if called from code
    End_Indicator<public>(Agent : ?agent):void=
        {
            if(SpawnedIndicator := IsSpawnedIndicator?):
                SpawnedIndicator.Dispose()
                set IsSpawnedIndicator = false
        }

    ##Internal logic to move the indicator.
    MoveIndicator()<suspends>:void=
        {
            if(SpawnedIndicator := IsSpawnedIndicator?):
                if(CurrentIndicator := indicator_positions[CurrentIndex]):
                    SpawnedIndicator.MoveTo(CurrentIndicator.GetTransform(), indicator_move_duration)
                else:
                    SpawnedIndicator.Dispose()
        }
