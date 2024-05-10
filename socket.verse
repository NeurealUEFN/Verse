using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Verse.org/Colors }


<#
1. Create a creative_device and add this socket manager as an editable variable on it. 
2. Fill the EditorSocketInfo array with all the sockets you want to attach
3. Call the InitSocket method whenever you want to initialize the object. Parent object will be the creative_device
4. For ease of use, try to break the complete prop into different parts and keep the origin of all of them same. You dont have to deal with changing the relative transform of every socket all the time.
5. You can also create more sockets in code using the CreateSocket method
6. To attach objects to this newly created socket, you can use the AttachToSocket method
7. You can also replace an existing prop on a socket by using the AttachToSocket method, remember that you should first cleanup the previous prop attached to the socket by using the GetSocketByName method to get the socket and then disposing the prop attached to it
8. Reminder that you need to spawn props first before attaching it using the socket manager
9. Once all the sockets are properly attached to your liking, call the MoveTo or Scale method on the socket manager and it should update all the objects at once. 
10. Calling a MoveTo or Scale will override previous MoveTo or Scale if it is currently ongoing
10. socket manager currently does not support rotation
#>

SocketManager<public>:= class<concrete>
{ 

var ParentObject : creative_device := creative_device{}
var Sockets : [string]socket := map{}
@editable var EditorSocketInfo : []socket_editorinterface := array{} #Editor interface to initialize all the sockets and props on it

#Call this method when you want to initialize an object with socket manager
InitSocket<public>(Parent : creative_device):void=
    {
        set ParentObject = Parent
        for(CurrentSocketInfo : EditorSocketInfo):
            CreateSocket(CurrentSocketInfo.SocketName, CurrentSocketInfo.RelativeTransform)
            AttachToSocket(CurrentSocketInfo.AttachedObject, CurrentSocketInfo.SocketName)
    }

#Get sockets by name and you can get their relative, world transform and also the object attached to it
GetSocketByName<public>(SocketName : string):?socket=
    {
        if(RequestedSocket := Sockets[SocketName]):
            return option{RequestedSocket}
        else:
            return false
    }

#Create sockets using verse
CreateSocket<public>(SocketName : string  , I_RelativeTransform : transform):void=
    {
        if(set Sockets[SocketName] = socket{RelativeTransform := I_RelativeTransform}):
            if(NewSocket := Sockets[SocketName]):
                worldtransform : transform := transform
                {
                    Translation := ParentObject.GetTransform().Translation + NewSocket.RelativeTransform.Translation
                }
                set NewSocket.WorldTransform = worldtransform
    }

#Interface to move all the objects at once as a single entity
MoveTo<public>(Target : vector3, overtime : float)<suspends>:void=
    {
        branch:
            ParentObject.MoveTo(Target, ParentObject.GetTransform().Rotation, overtime)
        MoveAllSockets(Target, overtime)
            
    }

#Interface to scale all the objects at once as a single entity
Scale<public>(scale : vector3, overtime : float)<suspends>:void=
    {
        Transform := transform
        {
            Scale := scale
            Translation := ParentObject.GetTransform().Translation
        }
        
        spawn{ParentObject.MoveTo(Transform, 1.0)}
        spawn{ScaleAllSockets(Transform, 1.0)}
    }

#Attach props to a specific socket that is already created using the editor interface or create socket method
AttachToSocket<public>(Object : creative_prop, SocketName : string):void=
    {   
        if(RequestedSocket := Sockets[SocketName]):
            set RequestedSocket.AttachedObject = Object
            if(RequestedSocket.AttachedObject.TeleportTo[RequestedSocket.WorldTransform]):
        else:
            Print("SOCKET NOT FOUND - {SocketName}")
    }

#Remove props from a specific socket that is already created using the editor interface or create socket method and return it to the user
RemoveFromSocket<public>(SocketName : string):creative_prop=
    {
        if(RequestedSocket := Sockets[SocketName]):
            removedobject := RequestedSocket.AttachedObject
            set RequestedSocket.AttachedObject = creative_prop{}
            return removedobject
        else:
            return creative_prop{}
    }

#Force update the position of all the attached objects.
UpdateAllSockets<public>()<suspends>:void=
    {
        for(currentsocket : Sockets):
            set currentsocket.WorldTransform.Translation = ParentObject.GetTransform().Translation + currentsocket.RelativeTransform.Translation
    }

MoveAllSockets(destination : vector3, duration : float)<suspends>:void=
    {
        for(Index->currentsocket : Sockets):
            spawn{currentsocket.AttachedObject.MoveTo(destination +  currentsocket.RelativeTransform.Translation, currentsocket.WorldTransform.Rotation, duration)}
    }

ScaleAllSockets(Transform : transform, duration : float)<suspends>:void=
    {
        for(currentsocket : Sockets):
            spawn{currentsocket.AttachedObject.MoveTo(Transform, duration)}            
    }
}

#Socket struct that holds all the socket info
socket<public>:= class<unique>():
    var RelativeTransform<public> : transform := transform{}
    var WorldTransform<public> : transform := transform{}
    var AttachedObject<public> : creative_prop := creative_prop{}

#Socket editor interface to update socket info directly through the editor
socket_editorinterface<public>:=class<concrete>():
    @editable var SocketName<public> : string := "Default"
    @editable var RelativeTransform<public> : transform := transform{}
    @editable var AttachedObject<public> : creative_prop := creative_prop{} 
