package com.studiophoto.photoappbackend.frame;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PhotoFrameService {

    private final PhotoFrameRepository photoFrameRepository;
    private final com.studiophoto.photoappbackend.service.NotificationService notificationService;

    public List<PhotoFrameDto> getActiveFrames() {
        return photoFrameRepository.findAllByActiveTrueOrderBySortOrderAscNameAsc().stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    public List<PhotoFrame> findAll() {
        return photoFrameRepository.findAll().stream()
                .sorted((a, b) -> {
                    int order = Integer.compare(a.getSortOrder(), b.getSortOrder());
                    if (order != 0) {
                        return order;
                    }
                    return a.getName().compareToIgnoreCase(b.getName());
                })
                .collect(Collectors.toList());
    }

    public Optional<PhotoFrame> findById(Long id) {
        return photoFrameRepository.findById(id);
    }

    public PhotoFrame save(PhotoFrame frame) {
        PhotoFrame saved = photoFrameRepository.save(frame);
        notificationService.sendSyncNotification("FRAMES_UPDATED");
        return saved;
    }

    public void deleteById(Long id) {
        photoFrameRepository.deleteById(id);
        notificationService.sendSyncNotification("FRAMES_UPDATED");
    }

    private PhotoFrameDto mapToDto(PhotoFrame frame) {
        List<String> imageList = frame.getImages() != null && !frame.getImages().isBlank()
                ? Arrays.stream(frame.getImages().split(","))
                        .map(String::trim)
                        .filter(s -> !s.isEmpty())
                        .collect(Collectors.toList())
                : List.of();
        return PhotoFrameDto.builder()
                .id(frame.getId())
                .name(frame.getName())
                .images(imageList)
                .description(frame.getDescription())
                .sortOrder(frame.getSortOrder())
                .build();
    }
}
