({
    doInit : function(component, event, helper) {
		window.setTimeout(
			$A.getCallback(function() {
				$A.enqueueAction(component.get('c.requestCoords'));
			}), 1000
		);
	},
	requestCoords: function(component, event, helper){
		if (navigator.geolocation) {
			navigator.geolocation.getCurrentPosition(
				function(position){
					component.set('v.isLoading', false);
					component.set('v.hasError', false);
					component.set('v.coords', position.coords);
					component.set('v.accuracy', Math.round(position.coords.accuracy));
				},
				function(){
					component.set('v.hasError', true);
				},
				{
					enableHighAccuracy: true,
					maximumAge: 0,
					timeout: 10000
				}
			);
		}
	},
	receivedCoords: function(component, event, helper){
		var coords = component.get('v.coords');
		component.set('v.markers', [
			{
				location: {
					Latitude: coords.latitude, 
					Longitude: coords.longitude
				}
			}
		]);
	},
	sendCoordinates: function(component, event, helper){
		var uEvent = component.get('c.updateEvent'),
			recordId = component.get('v.recordId'),
			coords = component.get('v.coords');
		uEvent.setParams({
			eventId: recordId,
			latValue: coords.latitude,
			lngValue: coords.longitude
		});
		uEvent.setCallback(this, function(response){
			$A.get("e.force:refreshView").fire();
			$A.get("e.force:closeQuickAction").fire();
		});
		$A.enqueueAction(uEvent);
	},
	cancelButtonClick: function(component, event, helper){
		$A.get("e.force:closeQuickAction").fire();
	},
	saveButtonClick: function(component, event, helper){
		$A.enqueueAction(component.get('c.sendCoordinates'));
	},
	refreshButtonClick:  function(component, event, helper){
		$A.enqueueAction(component.get('c.requestCoords'));
	}
})