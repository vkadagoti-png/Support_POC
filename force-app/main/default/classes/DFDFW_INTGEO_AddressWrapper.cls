/*
*********************************************************
Apex Class Name    : DFDFW_INTGEO_AddressWrapper
Created Date       : 7/3/2024
Author             : Cloud Synapps Inc.
Description        : Class used as wrapper to parse address candidate api response.
Test Class Name    : DFDFW_INTGEO_AddressWrapperTest
*********************************************************
*/
public class DFDFW_INTGEO_AddressWrapper{
		public list<candidates> candidates{get;set;}
		public spatialReference spatialReference{get;set;}
	public class spatialReference{
		public Integer latestWkid{get;set;}
		public Integer wkid{get;set;}
	}
	public class location{
		public Decimal x{get;set;}
		public Decimal y{get;set;}
	}
	public class extent{
		public Decimal xmin{get;set;}
		public Decimal xmax{get;set;}
		public Decimal ymax{get;set;}
		public Decimal ymin{get;set;}
	}
	public class candidates{
		public Decimal score{get;set;}
		public location location{get;set;}
		public extent extent{get;set;}
		public String address{get;set;}
	}
    
}