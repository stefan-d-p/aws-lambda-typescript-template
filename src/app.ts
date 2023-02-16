import {} from 'aws-lambda';

export const lambdaHandler = async (): Promise<string> => {
	console.error('Hier ein Fehler');
	return 'Hello World!';
};
