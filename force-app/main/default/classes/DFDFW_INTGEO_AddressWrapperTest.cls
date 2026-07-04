/*
*********************************************************
Apex Class Name    : DFDFW_INTGEO_AddressWrapperTest
Created Date       : 11/1/2024
Author             : Cloud Synapps Inc.
Description        : Class used as test class for DFDFW_INTGEO_AddressWrapper.
*********************************************************
*/
@isTest
private class DFDFW_INTGEO_AddressWrapperTest {
    
    @isTest
    static void testDFDFW_INTGEO_AddressWrapper() {
        // Create an instance of DFDFW_INTGEO_AddressWrapper
        DFDFW_INTGEO_AddressWrapper addressWrapper = new DFDFW_INTGEO_AddressWrapper();
        
        // Initialize and set values for spatialReference
        DFDFW_INTGEO_AddressWrapper.spatialReference spatialRef = new DFDFW_INTGEO_AddressWrapper.spatialReference();
        spatialRef.latestWkid = 4326;
        spatialRef.wkid = 102100;
        
        // Set spatialReference in addressWrapper
        addressWrapper.spatialReference = spatialRef;

        // Initialize and set values for location
        DFDFW_INTGEO_AddressWrapper.location loc = new DFDFW_INTGEO_AddressWrapper.location();
        loc.x = 34.0522;
        loc.y = -118.2437;

        // Initialize and set values for extent
        DFDFW_INTGEO_AddressWrapper.extent ext = new DFDFW_INTGEO_AddressWrapper.extent();
        ext.xmin = 34.0;
        ext.xmax = 34.1;
        ext.ymin = -118.3;
        ext.ymax = -118.2;

        // Initialize and set values for candidates
        DFDFW_INTGEO_AddressWrapper.candidates candidate = new DFDFW_INTGEO_AddressWrapper.candidates();
        candidate.score = 98.5;
        candidate.location = loc;
        candidate.extent = ext;
        candidate.address = '123 Main St, Los Angeles, CA';

        // Add candidate to the list in addressWrapper
        addressWrapper.candidates = new List<DFDFW_INTGEO_AddressWrapper.candidates>{ candidate };

        // Assertions to verify that values are correctly assigned
        Assert.isNotNull(addressWrapper, 'addressWrapper should not be null');
        Assert.isNotNull(addressWrapper.spatialReference, 'spatialReference should not be null');
        Assert.areEqual(4326, addressWrapper.spatialReference.latestWkid, 'latestWkid should match the assigned value');
        Assert.areEqual(102100, addressWrapper.spatialReference.wkid, 'wkid should match the assigned value');

        Assert.isNotNull(addressWrapper.candidates, 'candidates list should not be null');
        Assert.areEqual(1, addressWrapper.candidates.size(), 'candidates list should contain one entry');
        Assert.areEqual(98.5, addressWrapper.candidates[0].score, 'score should match the assigned value');
        Assert.areEqual(34.0522, addressWrapper.candidates[0].location.x, 'location.x should match the assigned value');
        Assert.areEqual(-118.2437, addressWrapper.candidates[0].location.y, 'location.y should match the assigned value');
        Assert.areEqual('123 Main St, Los Angeles, CA', addressWrapper.candidates[0].address, 'address should match the assigned value');

        Assert.areEqual(34.0, addressWrapper.candidates[0].extent.xmin, 'extent.xmin should match the assigned value');
        Assert.areEqual(34.1, addressWrapper.candidates[0].extent.xmax, 'extent.xmax should match the assigned value');
        Assert.areEqual(-118.3, addressWrapper.candidates[0].extent.ymin, 'extent.ymin should match the assigned value');
        Assert.areEqual(-118.2, addressWrapper.candidates[0].extent.ymax, 'extent.ymax should match the assigned value');
    }
}