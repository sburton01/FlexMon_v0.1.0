<cfcomponent hint="Base Skeleton Collector">
	<cffunction name="returnStruct" access="private" output="false" returntype="struct" hint="Returns a basic Structure that RemoteObjects/WS's can use.">
		<cfscript>
			var structStatus = structNew();
			structinsert(structStatus,"msg","OK"); // Detailed message that can be displayed to the user
			structinsert(structStatus,"isError",false); // Indicates if an Error Occured
			structinsert(structStatus,"returnStatus","OK"); // Machine Status Code that the calling function can act on.
			structinsert(structStatus,"data",""); // Point to an available query if available.
			structinsert(structStatus,"module",""); // Indicate what module this data is related to.	
		</cfscript>
		<cfreturn structStatus>
	</cffunction>
</cfcomponent>