package com.pqdag.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FragmentationRequest {
    private boolean cleanAfter = true; // Clean rawdata and bindata after fragmentation
}
