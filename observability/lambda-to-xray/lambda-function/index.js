const AWSXRay = require('aws-xray-sdk-core');

// Whenever you make a request to an AWS service using the SDK
// X-Ray will automatically create subsegments for those
const AWS = AWSXRay.captureAWS(require('aws-sdk'));

// Capture all HTTP clients
AWSXRay.captureHTTPsGlobal(require('http'));
AWSXRay.captureHTTPsGlobal(require('https'));

// Initialize other AWS services you want to trace
const s3 = new AWS.S3();

exports.handler = async (event, context) => {
  console.log('Processing event:', JSON.stringify(event, null, 2));

  try {
    // Create a custom subsegment to track business logic
    const segment = AWSXRay.getSegment();
    const subsegment = segment.addNewSubsegment('businessLogic');

    // Add annotations (indexed, searchable)
    subsegment.addAnnotation('userId', event.userId || 'anonymous');
    subsegment.addAnnotation('requestType', event.requestType || 'standard');
    subsegment.addAnnotation('environment', process.env.ENVIRONMENT || 'development');

    // Add metadata (not indexed, but provides rich context)
    subsegment.addMetadata('eventDetails', event, 'requestInfo');
    subsegment.addMetadata(
      'functionVersion',
      process.env.AWS_LAMBDA_FUNCTION_VERSION,
      'environment'
    );

    // Simulate some processing time
    await simulateProcessing();

    // Create a custom subsegment for business logic
    const s3Subsegment = segment.addNewSubsegment('processingUpload');
    let uploadResult;

    try {
      console.log(`Processing upload for user ${event.userId}`);

      // Upload to S3
      uploadResult = await s3
        .putObject({
          Bucket: 'your-bucket-name',
          Key: `uploads/${event.userId}/${event.filename}`,
          Body: Buffer.from(event.fileContent, 'base64'),
          ContentType: event.contentType
        })
        .promise();

      s3Subsegment.close();

      return {
        statusCode: 200,
        body: JSON.stringify({ success: true, etag: uploadResult.ETag })
      };
    } catch (error) {
      console.error('Upload failed:', error);
      s3Subsegment.addError(error);
      s3Subsegment.close();
    }

    // Example of conditional error tracking with X-Ray
    if (event.simulateError === true) {
      const error = new Error('Simulated business logic error');
      subsegment.addError(error);
      subsegment.close();
      throw error;
    }

    // Close the custom subsegment when done
    subsegment.close();

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Successfully processed request',
        data: uploadResult,
        traceId: segment.trace_id
      })
    };
  } catch (error) {
    console.error('Error processing request:', error);

    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing request',
        errorDetails: error.message,
        // Optionally include the trace ID in the response for correlation
        traceId: AWSXRay.getSegment().trace_id
      })
    };
  }
};

// Simulate some processing with random timing
async function simulateProcessing() {
  const processingTime = Math.floor(Math.random() * 500) + 100;

  // Create a custom subsegment for the processing
  const segment = AWSXRay.getSegment();
  const subsegment = segment.addNewSubsegment('dataProcessing');

  // Add metadata about the processing
  subsegment.addMetadata('processingTimeMs', processingTime, 'performance');

  await new Promise((resolve) => setTimeout(resolve, processingTime));

  // Close the subsegment
  subsegment.close();

  return true;
}
