// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'featured_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FeaturedContent _$FeaturedContentFromJson(Map<String, dynamic> json) {
  return _FeaturedContent.fromJson(json);
}

/// @nodoc
mixin _$FeaturedContent {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  String? get buttonText => throw _privateConstructorUsedError;
  String? get buttonAction => throw _privateConstructorUsedError;
  bool get active => throw _privateConstructorUsedError;
  int get priority => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this FeaturedContent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FeaturedContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeaturedContentCopyWith<FeaturedContent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeaturedContentCopyWith<$Res> {
  factory $FeaturedContentCopyWith(
          FeaturedContent value, $Res Function(FeaturedContent) then) =
      _$FeaturedContentCopyWithImpl<$Res, FeaturedContent>;
  @useResult
  $Res call(
      {int id,
      String title,
      String imageUrl,
      String? buttonText,
      String? buttonAction,
      bool active,
      int priority,
      DateTime createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$FeaturedContentCopyWithImpl<$Res, $Val extends FeaturedContent>
    implements $FeaturedContentCopyWith<$Res> {
  _$FeaturedContentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeaturedContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? imageUrl = null,
    Object? buttonText = freezed,
    Object? buttonAction = freezed,
    Object? active = null,
    Object? priority = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      buttonText: freezed == buttonText
          ? _value.buttonText
          : buttonText // ignore: cast_nullable_to_non_nullable
              as String?,
      buttonAction: freezed == buttonAction
          ? _value.buttonAction
          : buttonAction // ignore: cast_nullable_to_non_nullable
              as String?,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeaturedContentImplCopyWith<$Res>
    implements $FeaturedContentCopyWith<$Res> {
  factory _$$FeaturedContentImplCopyWith(_$FeaturedContentImpl value,
          $Res Function(_$FeaturedContentImpl) then) =
      __$$FeaturedContentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String title,
      String imageUrl,
      String? buttonText,
      String? buttonAction,
      bool active,
      int priority,
      DateTime createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$FeaturedContentImplCopyWithImpl<$Res>
    extends _$FeaturedContentCopyWithImpl<$Res, _$FeaturedContentImpl>
    implements _$$FeaturedContentImplCopyWith<$Res> {
  __$$FeaturedContentImplCopyWithImpl(
      _$FeaturedContentImpl _value, $Res Function(_$FeaturedContentImpl) _then)
      : super(_value, _then);

  /// Create a copy of FeaturedContent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? imageUrl = null,
    Object? buttonText = freezed,
    Object? buttonAction = freezed,
    Object? active = null,
    Object? priority = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$FeaturedContentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      buttonText: freezed == buttonText
          ? _value.buttonText
          : buttonText // ignore: cast_nullable_to_non_nullable
              as String?,
      buttonAction: freezed == buttonAction
          ? _value.buttonAction
          : buttonAction // ignore: cast_nullable_to_non_nullable
              as String?,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeaturedContentImpl
    with DiagnosticableTreeMixin
    implements _FeaturedContent {
  const _$FeaturedContentImpl(
      {required this.id,
      required this.title,
      required this.imageUrl,
      this.buttonText,
      this.buttonAction,
      required this.active,
      required this.priority,
      required this.createdAt,
      this.updatedAt});

  factory _$FeaturedContentImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeaturedContentImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final String imageUrl;
  @override
  final String? buttonText;
  @override
  final String? buttonAction;
  @override
  final bool active;
  @override
  final int priority;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FeaturedContent(id: $id, title: $title, imageUrl: $imageUrl, buttonText: $buttonText, buttonAction: $buttonAction, active: $active, priority: $priority, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'FeaturedContent'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('imageUrl', imageUrl))
      ..add(DiagnosticsProperty('buttonText', buttonText))
      ..add(DiagnosticsProperty('buttonAction', buttonAction))
      ..add(DiagnosticsProperty('active', active))
      ..add(DiagnosticsProperty('priority', priority))
      ..add(DiagnosticsProperty('createdAt', createdAt))
      ..add(DiagnosticsProperty('updatedAt', updatedAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeaturedContentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.buttonText, buttonText) ||
                other.buttonText == buttonText) &&
            (identical(other.buttonAction, buttonAction) ||
                other.buttonAction == buttonAction) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, imageUrl, buttonText,
      buttonAction, active, priority, createdAt, updatedAt);

  /// Create a copy of FeaturedContent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeaturedContentImplCopyWith<_$FeaturedContentImpl> get copyWith =>
      __$$FeaturedContentImplCopyWithImpl<_$FeaturedContentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeaturedContentImplToJson(
      this,
    );
  }
}

abstract class _FeaturedContent implements FeaturedContent {
  const factory _FeaturedContent(
      {required final int id,
      required final String title,
      required final String imageUrl,
      final String? buttonText,
      final String? buttonAction,
      required final bool active,
      required final int priority,
      required final DateTime createdAt,
      final DateTime? updatedAt}) = _$FeaturedContentImpl;

  factory _FeaturedContent.fromJson(Map<String, dynamic> json) =
      _$FeaturedContentImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  String get imageUrl;
  @override
  String? get buttonText;
  @override
  String? get buttonAction;
  @override
  bool get active;
  @override
  int get priority;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of FeaturedContent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeaturedContentImplCopyWith<_$FeaturedContentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
