import {} from 'aws-lambda';

interface In {
	name: string;
}

interface Out {
	greeting: string;
}

export const lambdaHandler = async (input: In): Promise<Out> => {
	let result: Out = { greeting: `Hello ${input.name}` };
	return result;
};
