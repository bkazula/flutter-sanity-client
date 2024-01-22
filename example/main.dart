import 'package:flutter_sanity_client/flutter_sanity_client.dart';

void main() async {
  final sanityClient = SanityClient(
    dataset: 'dataSet',
    projectId: 'projectId',
  );

  final response = await sanityClient.fetch('*[_type == "post"]');

  print(response);
}
