from django.urls import path
from .views import (
    LectureUploadView,
    LectureListView,
    ProcessLectureView,
    LectureStatusView,
    TranscriptDetailView,
)

urlpatterns = [
    path('lectures/', LectureListView.as_view(), name='lecture-list'),
    path('lectures/upload/', LectureUploadView.as_view(), name='lecture-upload'),
    path('lectures/<int:pk>/process/', ProcessLectureView.as_view(), name='lecture-process'),
    path('lectures/<int:pk>/status/', LectureStatusView.as_view(), name='lecture-status'),
    path('lectures/<int:lecture_id>/transcript/<str:language>/', TranscriptDetailView.as_view(), name='transcript-detail'),
]
