import 'dart:async';

import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_widgets.dart';
import '../prototype/theme_manager.dart';

class StudentHelpRequestScreen extends StatefulWidget {
  const StudentHelpRequestScreen({
    required this.apiClient,
    required this.identity,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;

  @override
  State<StudentHelpRequestScreen> createState() =>
      _StudentHelpRequestScreenState();
}

class _StudentHelpRequestScreenState extends State<StudentHelpRequestScreen> {
  static const _categories = <DropdownMenuItem<String>>[
    DropdownMenuItem(
      value: 'emotional_support',
      child: Text('Emotional support'),
    ),
    DropdownMenuItem(value: 'academic_stress', child: Text('Academic stress')),
    DropdownMenuItem(value: 'peer_issue', child: Text('Peer issue')),
    DropdownMenuItem(value: 'family_issue', child: Text('Family issue')),
    DropdownMenuItem(value: 'crisis', child: Text('Crisis')),
    DropdownMenuItem(value: 'other', child: Text('Other')),
  ];

  static const _urgencies = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: 'standard', child: Text('Standard')),
    DropdownMenuItem(value: 'priority', child: Text('Priority')),
    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
    DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
  ];

  final _summaryController = TextEditingController();
  final _detailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late Future<List<MobileSupportContact>> _contactsFuture;
  String _category = 'emotional_support';
  String _urgency = 'standard';
  bool _submitting = false;
  HelpRequestResponse? _submitted;

  @override
  void initState() {
    super.initState();
    _contactsFuture = widget.apiClient.listSupportContacts(
      identity: widget.identity,
    );
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _refreshContacts() async {
    setState(() {
      _contactsFuture = widget.apiClient.listSupportContacts(
        identity: widget.identity,
      );
    });
    await _contactsFuture;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final details = <String, dynamic>{};
      final note = _detailsController.text.trim();
      if (note.isNotEmpty) {
        details['note'] = note;
      }
      final response = await widget.apiClient.createStudentHelpRequest(
        identity: widget.identity,
        request: HelpRequestCreateRequest(
          category: _category,
          urgency: _urgency,
          summary: _summaryController.text.trim(),
          details: details,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _submitted = response;
      });
      _summaryController.clear();
      _detailsController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support request submitted.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPaletteForTheme(
      ThemeScope.of(context).colorTheme,
      isDark: ThemeScope.of(context).isDark,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: RefreshIndicator(
          onRefresh: _refreshContacts,
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  ThemeModeToggle(palette: palette),
                ],
              ),
              HeroHeader(
                palette: palette,
                kicker: 'SOS Help',
                title: 'Clear next steps when something feels unsafe.',
                subtitle:
                    'This is a real submission flow. Requests created here land in the counselor queue on the backend.',
                actions: const [
                  Pill(icon: Icons.health_and_safety_rounded, label: 'Safety'),
                  Pill(icon: Icons.cloud_done_rounded, label: 'Live backend'),
                ],
              ),
              const SizedBox(height: 18),
              GlassPanel(
                palette: palette,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        title: 'Request support',
                        subtitle:
                            'Private by default and routed to BAHA support.',
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        items: _categories,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _urgency,
                        items: _urgencies,
                        decoration: const InputDecoration(labelText: 'Urgency'),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _urgency = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _summaryController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Short summary',
                          hintText: 'Tell BAHA what kind of help you need.',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.length < 5) {
                            return 'Enter at least 5 characters.';
                          }
                          if (text.length > 500) {
                            return 'Keep the summary under 500 characters.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _detailsController,
                        minLines: 4,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'More detail (optional)',
                          hintText:
                              'Add context you want the counselor to see.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This current mobile flow submits private student support requests.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: palette.muted),
                      ),
                      const SizedBox(height: 18),
                      AnimatedPrimaryButton(
                        label: _submitting
                            ? 'Submitting...'
                            : 'Send support request',
                        icon: Icons.send_rounded,
                        onPressed: _submitting ? () {} : _submit,
                      ),
                    ],
                  ),
                ),
              ),
              if (_submitted != null) ...[
                const SizedBox(height: 18),
                GlassPanel(
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        title: 'Latest request',
                        subtitle: 'Confirmed by the live backend.',
                      ),
                      _SupportInfoRow(
                        label: 'Status',
                        value: _submitted!.status,
                      ),
                      _SupportInfoRow(
                        label: 'Category',
                        value: _submitted!.category,
                      ),
                      _SupportInfoRow(
                        label: 'Urgency',
                        value: _submitted!.urgency,
                      ),
                      _SupportInfoRow(
                        label: 'Created',
                        value: _formatDateTime(_submitted!.createdAt),
                      ),
                      _SupportInfoRow(
                        label: 'Summary',
                        value: _submitted!.summary,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FutureBuilder<List<MobileSupportContact>>(
                future: _contactsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return ShimmerBlock(palette: palette);
                  }
                  if (snapshot.hasError) {
                    return GlassPanel(
                      palette: palette,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Could not load support contacts.',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text('${snapshot.error}'),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => unawaited(_refreshContacts()),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  final contacts =
                      snapshot.data ?? const <MobileSupportContact>[];
                  return GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Available support contacts',
                          subtitle:
                              'School-scoped support information from the API.',
                        ),
                        if (contacts.isEmpty)
                          Text(
                            'No support contacts are available right now.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          )
                        else
                          ...contacts.map(
                            (contact) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _SupportContactTile(contact: contact),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportContactTile extends StatelessWidget {
  const _SupportContactTile({required this.contact});

  final MobileSupportContact contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(contact.label, style: theme.bodyLarge),
        const SizedBox(height: 4),
        Text(
          [
            contact.contactType.replaceAll('_', ' '),
            if (contact.serviceHours != null &&
                contact.serviceHours!.isNotEmpty)
              contact.serviceHours!,
          ].join(' • '),
          style: theme.bodyMedium,
        ),
        if (contact.phone != null && contact.phone!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Phone: ${contact.phone}', style: theme.bodyLarge),
        ],
        if (contact.email != null && contact.email!.isNotEmpty)
          Text('Email: ${contact.email}', style: theme.bodyLarge),
      ],
    );
  }
}

class _SupportInfoRow extends StatelessWidget {
  const _SupportInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value, style: theme.bodyLarge)),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(local)} ${local.hour}:$minute';
}
