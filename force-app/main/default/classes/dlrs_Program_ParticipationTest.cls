/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Program_ParticipationTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Program_ParticipationTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Program_Participation__c());
    }
}