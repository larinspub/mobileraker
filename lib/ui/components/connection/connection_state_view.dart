/*
 * Copyright (c) 2023. Patrick Schmidt.
 * All rights reserved.
 */

import 'package:common/network/jrpc_client_provider.dart';
import 'package:common/network/json_rpc_client.dart';
import 'package:common/service/app_router.dart';
import 'package:common/service/selected_machine_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobileraker/routing/app_router.dart';
import 'package:mobileraker/ui/components/async_value_widget.dart';
import 'package:mobileraker/ui/components/connection/connection_state_controller.dart';
import 'package:mobileraker/ui/components/connection/klippy_state_widget.dart';
import 'package:mobileraker/ui/components/error_card.dart';
import 'package:progress_indicators/progress_indicators.dart';

class ConnectionStateView extends ConsumerWidget {
  const ConnectionStateView({
    Key? key,
    required this.onConnected,
    this.skipKlipperReady = false,
  }) : super(key: key);

  // Widget to show when ws is Connected
  final Widget onConnected;
  final bool skipKlipperReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var machine = ref.watch(selectedMachineProvider);

    return Center(
      child: machine.when(
        data: (machine) {
          return machine != null
              ? _WebsocketStateWidget(
                  onConnected: onConnected,
                  skipKlipperReady: skipKlipperReady,
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: SvgPicture.asset(
                          'assets/vector/undraw_hello_re_3evm.svg',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Text(
                          'components.connection_watcher.add_printer',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ).tr(),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => ref.read(goRouterProvider).pushNamed(AppRoute.printerAdd.name),
                        icon: const Icon(Icons.add),
                        label: const Text('pages.overview.add_machine').tr(),
                      ),
                      const Spacer(),
                    ],
                  ),
                );
        },
        error: (e, _) => ErrorCard(
          title: const Text('Error selecting active machine'),
          body: Text(e.toString()),
        ),
        loading: () => const CircularProgressIndicator.adaptive(),
        skipLoadingOnRefresh: false,
      ),
    );
  }
}

class _WebsocketStateWidget extends HookConsumerWidget {
  const _WebsocketStateWidget({
    Key? key,
    required this.onConnected,
    this.skipKlipperReady = false,
  }) : super(key: key);
  final Widget onConnected;

  final bool skipKlipperReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<ClientState> connectionState = ref.watch(connectionStateControllerProvider);
    ClientType clientType = ref.watch(jrpcClientSelectedProvider.select((value) => value.clientType));

    var connectionStateController = ref.watch(connectionStateControllerProvider.notifier);

    return AsyncValueWidget(
      key: ValueKey(clientType),
      value: connectionState,
      data: (ClientState clientState) {
        switch (clientState) {
          case ClientState.connected:
            return KlippyStateWidget(
              onConnected: onConnected,
              skipKlipperReady: skipKlipperReady,
            );

          case ClientState.disconnected:
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  size: 50,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 30),
                const Text('@:klipper_state.disconnected !').tr(),
                TextButton.icon(
                  onPressed: connectionStateController.onRetryPressed,
                  icon: const Icon(Icons.restart_alt_outlined),
                  label: const Text('components.connection_watcher.reconnect').tr(),
                ),
              ],
            );
          case ClientState.connecting:
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (clientType == ClientType.local)
                  SpinKitPulse(
                    size: 100,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                if (clientType == ClientType.octo)
                  SpinKitPouringHourGlassRefined(
                    size: 100,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                const SizedBox(height: 30),
                FadingText(tr(clientType == ClientType.local
                    ? 'components.connection_watcher.trying_connect'
                    : 'components.connection_watcher.trying_connect_remote')),
              ],
            );
          case ClientState.error:
          default:
            return Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    size: 50,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    connectionStateController.clientErrorMessage,
                    textAlign: TextAlign.center,
                  ),
                  if (!connectionStateController.errorIsOctoSupportedExpired)
                    TextButton.icon(
                      onPressed: connectionStateController.onRetryPressed,
                      icon: const Icon(Icons.restart_alt_outlined),
                      label: const Text(
                        'components.connection_watcher.reconnect',
                      ).tr(),
                    ),
                  if (connectionStateController.errorIsOctoSupportedExpired)
                    TextButton.icon(
                      onPressed: connectionStateController.onGoToOE,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text(
                        'components.connection_watcher.more_details',
                      ).tr(),
                    ),
                ],
              ),
            );
        }
      },
    );
  }
}
