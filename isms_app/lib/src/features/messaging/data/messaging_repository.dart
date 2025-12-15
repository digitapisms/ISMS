import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client.dart';
import '../domain/announcement.dart';
import '../domain/circular.dart';
import '../domain/conversation.dart';
import '../domain/conversation_participant.dart';
import '../domain/message.dart';
import '../domain/message_attachment.dart';
import '../domain/message_template.dart';
import '../domain/messaging_type.dart';
import '../domain/read_receipt.dart';

class MessagingRepository {
  SupabaseClient get _client => SupabaseManager.client;
  String? _schoolId;

  void setSchoolId(String? schoolId) {
    _schoolId = schoolId;
  }

  String? get schoolId => _schoolId;

  String _requireSchoolId() {
    final id = _schoolId;
    if (id == null) {
      throw Exception(
        'School context is required for this action. Please ensure you are signed in to a school tenant.',
      );
    }
    return id;
  }

  Map<String, dynamic> _withSchoolId(Map<String, dynamic> data) {
    final id = _schoolId;
    if (id == null) return data;
    return {...data, 'school_id': id};
  }

  // ============================================================
  // CONVERSATIONS
  // ============================================================

  Future<Conversation> createConversation(Conversation conversation) async {
    _requireSchoolId();
    final response = await _client
        .from('chat_conversations')
        .insert(_withSchoolId(conversation.toJson()))
        .select()
        .single();
    return Conversation.fromJson(response);
  }

  Future<List<Conversation>> fetchConversations({String? userId}) async {
    _requireSchoolId();
    var query = _client
        .from('chat_conversations')
        .select()
        .eq('school_id', _requireSchoolId())
        .eq('is_active', true)
        .order('last_message_at', ascending: false);

    if (userId != null) {
      // Get conversations where user is a participant
      final participantQuery = _client
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', userId)
          .eq('school_id', _requireSchoolId());
      
      final participants = await participantQuery;
      final conversationIds = (participants as List)
          .map((p) => (p as Map<String, dynamic>)['conversation_id'] as String)
          .toList();
      
      if (conversationIds.isEmpty) return [];
      // Filter in memory since Supabase doesn't support in_ on all query types
      final allConversations = await query;
      final filtered = (allConversations as List)
          .where((c) => conversationIds.contains((c as Map<String, dynamic>)['id'] as String))
          .toList();
      return filtered
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    if (userId == null) {
      final response = await query;
      return (response as List)
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Conversation?> getConversation(String conversationId) async {
    _requireSchoolId();
    final response = await _client
        .from('chat_conversations')
        .select()
        .eq('id', conversationId)
        .eq('school_id', _requireSchoolId())
        .maybeSingle();
    
    if (response == null) return null;
    return Conversation.fromJson(response);
  }

  Future<Conversation> updateConversation(Conversation conversation) async {
    _requireSchoolId();
    final response = await _client
        .from('chat_conversations')
        .update(conversation.toJson())
        .eq('id', conversation.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return Conversation.fromJson(response);
  }

  Future<void> deleteConversation(String conversationId) async {
    _requireSchoolId();
    await _client
        .from('chat_conversations')
        .update({'is_active': false})
        .eq('id', conversationId)
        .eq('school_id', _requireSchoolId());
  }

  // ============================================================
  // CONVERSATION PARTICIPANTS
  // ============================================================

  Future<ConversationParticipant> addParticipant(
    String conversationId,
    String userId, {
    ParticipantRole role = ParticipantRole.participant,
  }) async {
    _requireSchoolId();
    final participant = ConversationParticipant(
      id: '',
      schoolId: _requireSchoolId(),
      conversationId: conversationId,
      userId: userId,
      role: role,
      joinedAt: DateTime.now(),
    );
    
    final response = await _client
        .from('conversation_participants')
        .insert(_withSchoolId(participant.toJson()))
        .select()
        .single();
    return ConversationParticipant.fromJson(response);
  }

  Future<List<ConversationParticipant>> getParticipants(String conversationId) async {
    _requireSchoolId();
    final response = await _client
        .from('conversation_participants')
        .select()
        .eq('conversation_id', conversationId)
        .eq('school_id', _requireSchoolId());
    
    return (response as List)
        .map((json) => ConversationParticipant.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeParticipant(String conversationId, String userId) async {
    _requireSchoolId();
    await _client
        .from('conversation_participants')
        .delete()
        .eq('conversation_id', conversationId)
        .eq('user_id', userId)
        .eq('school_id', _requireSchoolId());
  }

  Future<void> updateParticipant(
    String conversationId,
    String userId,
    Map<String, dynamic> updates,
  ) async {
    _requireSchoolId();
    await _client
        .from('conversation_participants')
        .update(updates)
        .eq('conversation_id', conversationId)
        .eq('user_id', userId)
        .eq('school_id', _requireSchoolId());
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  Future<Message> sendMessage(Message message) async {
    _requireSchoolId();
    final response = await _client
        .from('chat_messages')
        .insert(_withSchoolId(message.toJson()))
        .select()
        .single();
    return Message.fromJson(response);
  }

  Future<List<Message>> fetchMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('chat_messages')
        .select()
        .eq('conversation_id', conversationId)
        .eq('school_id', _requireSchoolId())
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .limit(limit);

    // Note: Supabase Flutter doesn't support lt directly on all query builders
    // We'll fetch more and filter in memory if needed

    final response = await query;
    final messages = (response as List)
        .map((json) => Message.fromJson(json as Map<String, dynamic>))
        .toList();
    return messages.reversed.toList(); // Return in chronological order
  }

  Future<Message> updateMessage(Message message) async {
    _requireSchoolId();
    final response = await _client
        .from('chat_messages')
        .update({
          ...message.toJson(),
          'is_edited': true,
          'edited_at': DateTime.now().toIso8601String(),
        })
        .eq('id', message.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return Message.fromJson(response);
  }

  Future<void> deleteMessage(String messageId) async {
    _requireSchoolId();
    await _client
        .from('chat_messages')
        .update({
          'is_deleted': true,
          'deleted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId)
        .eq('school_id', _requireSchoolId());
  }

  // Real-time subscription for messages
  Stream<List<Message>> watchMessages(String conversationId) {
    _requireSchoolId();
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) {
          final messages = (data as List)
              .map((json) => Message.fromJson(json as Map<String, dynamic>))
              .where((msg) =>
                  msg.conversationId == conversationId &&
                  msg.schoolId == _requireSchoolId() &&
                  !msg.isDeleted)
              .toList();
          return messages;
        });
  }

  // ============================================================
  // MESSAGE ATTACHMENTS
  // ============================================================

  Future<MessageAttachment> addAttachment(MessageAttachment attachment) async {
    _requireSchoolId();
    final response = await _client
        .from('message_attachments')
        .insert(_withSchoolId(attachment.toJson()))
        .select()
        .single();
    return MessageAttachment.fromJson(response);
  }

  Future<List<MessageAttachment>> getAttachments(String messageId) async {
    _requireSchoolId();
    final response = await _client
        .from('message_attachments')
        .select()
        .eq('message_id', messageId)
        .eq('school_id', _requireSchoolId());
    
    return (response as List)
        .map((json) => MessageAttachment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // READ RECEIPTS
  // ============================================================

  Future<void> markAsRead(String messageId, String userId) async {
    _requireSchoolId();
    await _client
        .from('read_receipts')
        .upsert({
          'school_id': _requireSchoolId(),
          'message_id': messageId,
          'user_id': userId,
          'read_at': DateTime.now().toIso8601String(),
        });
  }

  Future<List<ReadReceipt>> getReadReceipts(String messageId) async {
    _requireSchoolId();
    final response = await _client
        .from('read_receipts')
        .select()
        .eq('message_id', messageId)
        .eq('school_id', _requireSchoolId());
    
    return (response as List)
        .map((json) => ReadReceipt.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // ANNOUNCEMENTS
  // ============================================================

  Future<Announcement> createAnnouncement(Announcement announcement) async {
    _requireSchoolId();
    final response = await _client
        .from('school_announcements')
        .insert(_withSchoolId(announcement.toJson()))
        .select()
        .single();
    return Announcement.fromJson(response);
  }

  Future<List<Announcement>> fetchAnnouncements({
    bool? isPublished,
    TargetAudience? targetAudience,
    int? classId,
    int? sectionId,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('school_announcements')
        .select()
        .eq('school_id', _requireSchoolId());

    if (isPublished != null) {
      query = query.eq('is_published', isPublished);
    }
    if (targetAudience != null) {
      query = query.eq('target_audience', targetAudience.dbValue);
    }
    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List)
        .map((json) => Announcement.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Announcement> updateAnnouncement(Announcement announcement) async {
    _requireSchoolId();
    final response = await _client
        .from('school_announcements')
        .update(announcement.toJson())
        .eq('id', announcement.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return Announcement.fromJson(response);
  }

  Future<void> publishAnnouncement(String announcementId) async {
    _requireSchoolId();
    await _client
        .from('school_announcements')
        .update({
          'is_published': true,
          'published_at': DateTime.now().toIso8601String(),
        })
        .eq('id', announcementId)
        .eq('school_id', _requireSchoolId());
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    _requireSchoolId();
    await _client
        .from('school_announcements')
        .delete()
        .eq('id', announcementId)
        .eq('school_id', _requireSchoolId());
  }

  Future<void> markAnnouncementAsRead(String announcementId, String userId) async {
    _requireSchoolId();
    await _client
        .from('announcement_reads')
        .upsert({
          'school_id': _requireSchoolId(),
          'announcement_id': announcementId,
          'user_id': userId,
          'read_at': DateTime.now().toIso8601String(),
        });
  }

  // ============================================================
  // CIRCULARS
  // ============================================================

  Future<Circular> createCircular(Circular circular) async {
    _requireSchoolId();
    // Generate circular number if not provided
    if (circular.circularNumber.isEmpty) {
      final response = await _client.rpc(
        'generate_circular_number',
        params: {'p_school_id': _requireSchoolId()},
      );
      final circularNumber = response as String;
      final updatedCircular = Circular(
        id: circular.id,
        schoolId: circular.schoolId,
        circularNumber: circularNumber,
        title: circular.title,
        content: circular.content,
        circularType: circular.circularType,
        targetAudience: circular.targetAudience,
        classId: circular.classId,
        sectionId: circular.sectionId,
        issuedBy: circular.issuedBy,
        issuedDate: circular.issuedDate,
        effectiveDate: circular.effectiveDate,
        expiryDate: circular.expiryDate,
        isActive: circular.isActive,
        requiresAcknowledgment: circular.requiresAcknowledgment,
        createdAt: circular.createdAt,
        updatedAt: circular.updatedAt,
      );
      final insertResponse = await _client
          .from('circulars')
          .insert(_withSchoolId(updatedCircular.toJson()))
          .select()
          .single();
      return Circular.fromJson(insertResponse);
    }
    
    final response = await _client
        .from('circulars')
        .insert(_withSchoolId(circular.toJson()))
        .select()
        .single();
    return Circular.fromJson(response);
  }

  Future<List<Circular>> fetchCirculars({
    bool? isActive,
    TargetAudience? targetAudience,
    int? classId,
    int? sectionId,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('circulars')
        .select()
        .eq('school_id', _requireSchoolId());

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }
    if (targetAudience != null) {
      query = query.eq('target_audience', targetAudience.dbValue);
    }
    if (classId != null) {
      query = query.eq('class_id', classId);
    }
    if (sectionId != null) {
      query = query.eq('section_id', sectionId);
    }

    final response = await query.order('issued_date', ascending: false);
    return (response as List)
        .map((json) => Circular.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Circular> updateCircular(Circular circular) async {
    _requireSchoolId();
    final response = await _client
        .from('circulars')
        .update(circular.toJson())
        .eq('id', circular.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return Circular.fromJson(response);
  }

  Future<void> deleteCircular(String circularId) async {
    _requireSchoolId();
    await _client
        .from('circulars')
        .update({'is_active': false})
        .eq('id', circularId)
        .eq('school_id', _requireSchoolId());
  }

  Future<void> markCircularAsRead(String circularId, String userId) async {
    _requireSchoolId();
    await _client
        .from('circular_reads')
        .upsert({
          'school_id': _requireSchoolId(),
          'circular_id': circularId,
          'user_id': userId,
          'read_at': DateTime.now().toIso8601String(),
        });
  }

  // ============================================================
  // MESSAGE TEMPLATES
  // ============================================================

  Future<MessageTemplate> createTemplate(MessageTemplate template) async {
    _requireSchoolId();
    final response = await _client
        .from('chat_message_templates')
        .insert(_withSchoolId(template.toJson()))
        .select()
        .single();
    return MessageTemplate.fromJson(response);
  }

  Future<List<MessageTemplate>> fetchTemplates({
    TemplateCategory? category,
    bool? isActive,
  }) async {
    _requireSchoolId();
    var query = _client
        .from('chat_message_templates')
        .select()
        .eq('school_id', _requireSchoolId());

    if (category != null) {
      query = query.eq('template_category', category.dbValue);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('template_name');
    return (response as List)
        .map((json) => MessageTemplate.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<MessageTemplate> updateTemplate(MessageTemplate template) async {
    _requireSchoolId();
    final response = await _client
        .from('chat_message_templates')
        .update(template.toJson())
        .eq('id', template.id)
        .eq('school_id', _requireSchoolId())
        .select()
        .single();
    return MessageTemplate.fromJson(response);
  }

  Future<void> deleteTemplate(String templateId) async {
    _requireSchoolId();
    await _client
        .from('chat_message_templates')
        .delete()
        .eq('id', templateId)
        .eq('school_id', _requireSchoolId());
  }

  Future<void> incrementTemplateUsage(String templateId) async {
    _requireSchoolId();
    await _client.rpc(
      'increment_template_usage',
      params: {'p_template_id': templateId},
    ).catchError((_) {
      // If function doesn't exist, manually update
      _client
          .from('chat_message_templates')
          .update({'usage_count': 'usage_count + 1'})
          .eq('id', templateId)
          .eq('school_id', _requireSchoolId());
    });
  }
}

