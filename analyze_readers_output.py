#!/usr/bin/env python3
"""
Script để phân tích output của các reader bằng cách đọc file H5
và mô phỏng logic của reader MATLAB
"""

import h5py
import os
import json
import numpy as np

def analyze_h5_structure(filepath, reader_type):
    """Phân tích cấu trúc H5 và mô phỏng output của reader"""
    if not os.path.exists(filepath):
        return None
    
    result = {
        'file': os.path.basename(filepath),
        'reader': reader_type,
        'structure': {},
        'output_simulation': {}
    }
    
    try:
        with h5py.File(filepath, 'r') as f:
            # Phân tích cấu trúc
            result['structure'] = analyze_structure(f, '/')
            
            # Mô phỏng output dựa trên reader type
            if reader_type == 'read_df':
                result['output_simulation'] = simulate_df_reader(f)
            elif reader_type == 'read_identifier':
                result['output_simulation'] = simulate_identifier_reader(f)
            elif reader_type == 'read_spectrum_data':
                result['output_simulation'] = simulate_spectrum_reader(f)
            elif reader_type == 'read_histogram_h5_multitype':
                result['output_simulation'] = simulate_histogram_reader(f)
            elif reader_type == 'read_iq_ethernet_h5_verge':
                result['output_simulation'] = simulate_iq_ethernet_reader(f)
            elif reader_type == 'read_iqtcp_h5_verge2':
                result['output_simulation'] = simulate_iqtcp_reader(f)
            elif reader_type == 'reader_demodulation_no_recursive':
                result['output_simulation'] = simulate_demodulation_reader(f)
                
    except Exception as e:
        result['error'] = str(e)
        import traceback
        result['traceback'] = traceback.format_exc()
    
    return result

def analyze_structure(obj, path, depth=0, max_depth=3):
    """Phân tích cấu trúc H5"""
    structure = {}
    
    if depth > max_depth:
        return structure
    
    if isinstance(obj, h5py.Group):
        structure['type'] = 'Group'
        structure['attributes'] = {k: str(v) for k, v in obj.attrs.items()}
        structure['children'] = {}
        
        for key in obj.keys():
            child_path = f"{path}/{key}" if path != '/' else f"/{key}"
            structure['children'][key] = analyze_structure(obj[key], child_path, depth+1, max_depth)
            
    elif isinstance(obj, h5py.Dataset):
        structure['type'] = 'Dataset'
        structure['dtype'] = str(obj.dtype)
        structure['shape'] = obj.shape
        structure['attributes'] = {k: str(v) for k, v in obj.attrs.items()}
    
    return structure

def simulate_df_reader(f):
    """Mô phỏng output của read_df"""
    output = {}
    
    if 'attribute' in f:
        attr = f['attribute']
        
        # Configuration
        if 'configuration' in attr:
            output['configuration'] = {}
            conf = attr['configuration']
            for key in conf.keys():
                output['configuration'][key] = {
                    'attributes': {k: str(v) for k, v in conf[key].attrs.items()}
                }
        
        # Calibration
        if 'calibration' in attr and 'calibs' in attr['calibration']:
            output['calibration'] = {}
            calibs = attr['calibration']['calibs']
            for key in calibs.keys():
                table_name = f"Table_{key}"
                output['calibration'][table_name] = {}
                calib_group = calibs[key]
                for ds_name in calib_group.keys():
                    if isinstance(calib_group[ds_name], h5py.Dataset):
                        ds = calib_group[ds_name]
                        output['calibration'][table_name][ds_name] = {
                            'shape': ds.shape,
                            'dtype': str(ds.dtype)
                        }
    
    # Sessions
    if 'session' in f:
        sessions = list(f['session'].keys())
        output['sessions'] = []
        for sess_id in sessions[:3]:  # Chỉ lấy 3 session đầu
            sess = f['session'][sess_id]
            sess_data = {
                'id': sess_id,
                'pulses': {},
                'doa': {}
            }
            
            # Pulses (datasets trực tiếp trong session)
            for key in sess.keys():
                if isinstance(sess[key], h5py.Dataset):
                    sess_data['pulses'][key] = {
                        'shape': sess[key].shape,
                        'dtype': str(sess[key].dtype)
                    }
            
            # DOA structure
            if 'doa' in sess and 'doa' in sess['doa']:
                doa2 = sess['doa']['doa']
                for target_id in list(doa2.keys())[:2]:  # Chỉ lấy 2 target đầu
                    target_name = f"Target_{target_id}"
                    sess_data['doa'][target_name] = {}
                    
                    target = doa2[target_id]
                    if 'position' in target:
                        sess_data['doa'][target_name]['position'] = {}
                        for ds_name in target['position'].keys():
                            if isinstance(target['position'][ds_name], h5py.Dataset):
                                sess_data['doa'][target_name]['position'][ds_name] = {
                                    'shape': target['position'][ds_name].shape
                                }
            
            output['sessions'].append(sess_data)
    
    return output

def simulate_identifier_reader(f):
    """Mô phỏng output của read_identifier"""
    output = {}
    
    if 'attribute' in f:
        attr = f['attribute']
        
        # estm_bdw
        if 'estm_bdw' in attr:
            output['estm_bdw'] = {}
            for ds_name in attr['estm_bdw'].keys():
                if isinstance(attr['estm_bdw'][ds_name], h5py.Dataset):
                    output['estm_bdw'][ds_name] = {
                        'shape': attr['estm_bdw'][ds_name].shape
                    }
        
        # request.label
        if 'request' in attr and 'label' in attr['request']:
            output['request'] = {'label': 'parsed_struct'}
        
        # doa
        if 'doa' in attr:
            output['doa'] = {}
            if 'position' in attr['doa']:
                output['doa']['position'] = {}
                for ds_name in attr['doa']['position'].keys():
                    if isinstance(attr['doa']['position'][ds_name], h5py.Dataset):
                        output['doa']['position'][ds_name] = {
                            'shape': attr['doa']['position'][ds_name].shape
                        }
    
    # Sessions
    if 'session' in f:
        sessions = list(f['session'].keys())
        output['sessions'] = []
        for sess_id in sessions[:2]:
            sess = f['session'][sess_id]
            sess_data = {
                'id': sess_id,
                'iq': 'complex_array' if 'iq' in sess else None
            }
            output['sessions'].append(sess_data)
    
    return output

def simulate_spectrum_reader(f):
    """Mô phỏng output của read_spectrum_data"""
    output = {}
    
    # global_info
    if 'attribute' in f:
        output['global_info'] = {
            'attributes': {k: str(v) for k, v in f['attribute'].attrs.items()}
        }
    
    # sessions
    if 'session' in f:
        sessions = list(f['session'].keys())
        output['sessions'] = []
        for sess_id in sessions[:2]:
            sess = f['session'][sess_id]
            sess_data = {
                'id': sess_id,
                'attributes': {k: str(v) for k, v in sess.attrs.items()},
                'source_info': {},
                'samples': None
            }
            
            if 'source' in sess:
                sess_data['source_info'] = {
                    'attributes': {k: str(v) for k, v in sess['source'].attrs.items()}
                }
            
            if 'sample_decoded' in sess:
                sess_data['samples'] = {
                    'shape': sess['sample_decoded'].shape,
                    'dtype': str(sess['sample_decoded'].dtype)
                }
            
            output['sessions'].append(sess_data)
    
    return output

def simulate_histogram_reader(f):
    """Mô phỏng output của read_histogram_h5_multitype"""
    output = {}
    
    # global_info
    if 'attribute' in f:
        output['global_info'] = {
            'attributes': {k: str(v) for k, v in f['attribute'].attrs.items()}
        }
    
    # sessions
    if 'session' in f:
        sessions = list(f['session'].keys())
        output['sessions'] = []
        for sess_id in sessions[:2]:
            sess = f['session'][sess_id]
            sess_data = {
                'id': sess_id,
                'type': sess.attrs.get('message_type', b'').decode('utf-8', errors='ignore') if 'message_type' in sess.attrs else '',
                'attributes': {k: str(v) for k, v in sess.attrs.items()},
                'context_info': {},
                'source_info': {},
                'sample_decoded': None,
                'acc_sample_decoded': None,
                'crx_sample_decoded': None
            }
            
            if 'context' in sess:
                sess_data['context_info'] = {
                    'attributes': {k: str(v) for k, v in sess['context'].attrs.items()}
                }
            
            if 'source' in sess:
                sess_data['source_info'] = {
                    'attributes': {k: str(v) for k, v in sess['source'].attrs.items()}
                }
            
            # Kiểm tra message type
            msg_type = sess_data['type']
            if 'CrossingThresholdPower' in msg_type:
                if 'acc_sample_decoded' in sess:
                    sess_data['acc_sample_decoded'] = {'shape': sess['acc_sample_decoded'].shape}
                if 'crx_sample_decoded' in sess:
                    sess_data['crx_sample_decoded'] = {'shape': sess['crx_sample_decoded'].shape}
            else:
                if 'sample_decoded' in sess:
                    sess_data['sample_decoded'] = {'shape': sess['sample_decoded'].shape}
            
            output['sessions'].append(sess_data)
    
    return output

def simulate_iq_ethernet_reader(f):
    """Mô phỏng output của read_iq_ethernet_h5_verge"""
    output = {}
    
    # global_info
    if 'attribute' in f:
        output['global_info'] = {
            'attributes': {k: str(v) for k, v in f['attribute'].attrs.items()}
        }
        # Subgroups
        for key in f['attribute'].keys():
            if isinstance(f['attribute'][key], h5py.Group):
                output['global_info'][key] = {
                    'attributes': {k: str(v) for k, v in f['attribute'][key].attrs.items()}
                }
    
    # streams (sẽ được nhóm theo stream_id sau khi parse)
    if 'session' in f:
        sessions = list(f['session'].keys())
        output['streams_info'] = {
            'num_sessions': len(sessions),
            'note': 'Packets will be grouped by stream_id after parsing'
        }
    
    return output

def simulate_iqtcp_reader(f):
    """Mô phỏng output của read_iqtcp_h5_verge2"""
    output = {}
    
    # global_info
    if 'attribute' in f:
        output['global_info'] = {
            'attributes': {k: str(v) for k, v in f['attribute'].attrs.items()}
        }
        
        # ddc_info
        if 'ddc' in f['attribute']:
            output['ddc_info'] = {
                'attributes': {k: str(v) for k, v in f['attribute']['ddc'].attrs.items()}
            }
        
        # request_info
        if 'request' in f['attribute']:
            output['request_info'] = {
                'attributes': {k: str(v) for k, v in f['attribute']['request'].attrs.items()}
            }
            if 'label' in f['attribute']['request']:
                output['request_info']['label'] = 'dataset'
    
    # sessions
    if 'session' in f:
        sessions = list(f['session'].keys())
        output['sessions'] = []
        for sess_id in sessions[:2]:
            sess = f['session'][sess_id]
            sess_data = {
                'id': sess_id,
                'i': {'shape': sess['i'].shape, 'dtype': str(sess['i'].dtype)} if 'i' in sess else None,
                'q': {'shape': sess['q'].shape, 'dtype': str(sess['q'].dtype)} if 'q' in sess else None,
                'iq': 'complex_array (I + j*Q)'
            }
            output['sessions'].append(sess_data)
    
    return output

def simulate_demodulation_reader(f):
    """Mô phỏng output của reader_demodulation_no_recursive"""
    output = {}
    
    # request
    if 'attribute' in f and 'request' in f['attribute']:
        req = f['attribute']['request']
        output['request'] = {}
        for key in req.keys():
            if isinstance(req[key], h5py.Group):
                output['request'][key] = {
                    'attributes': {k: str(v) for k, v in req[key].attrs.items()}
                }
    
    # sessions
    if 'session' in f:
        sessions = list(f['session'].keys())
        output['sessions'] = []
        for sess_id in sessions[:2]:
            sess = f['session'][sess_id]
            sess_data = {
                'id': sess_id,
                'iq': 'complex_array (from i and q datasets)'
            }
            if 'i' in sess and 'q' in sess:
                sess_data['i_shape'] = sess['i'].shape
                sess_data['q_shape'] = sess['q'].shape
            output['sessions'].append(sess_data)
    
    return output

if __name__ == '__main__':
    base_path = '/home/tth193/Documents/h5_code/00_DATA_h5/'
    
    files_config = [
        ('df.h5', 'read_df'),
        ('identifier.h5', 'read_identifier'),
        ('demodulation.h5', 'reader_demodulation_no_recursive'),
        ('spectrum.h5', 'read_spectrum_data'),
        ('histogram.h5', 'read_histogram_h5_multitype'),
        ('iqethernet.h5', 'read_iq_ethernet_h5_verge'),
        ('iqtcp.h5', 'read_iqtcp_h5_verge2'),
    ]
    
    all_results = {}
    
    for filename, reader_type in files_config:
        filepath = os.path.join(base_path, filename)
        print(f"Processing {filename}...")
        result = analyze_h5_structure(filepath, reader_type)
        if result:
            all_results[filename] = result
    
    # Lưu kết quả
    output_file = '/home/tth193/Documents/h5_code/reader_output_analysis.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(all_results, f, indent=2, default=str)
    
    print(f"\nKết quả đã được lưu vào: {output_file}")
    
    # In tóm tắt
    print("\n=== TÓM TẮT OUTPUT STRUCTURE ===\n")
    for filename, result in all_results.items():
        if 'error' not in result:
            print(f"{filename} ({result['reader']}):")
            print_output_structure(result['output_simulation'], '  ')
            print()

def print_output_structure(obj, indent=''):
    """In cấu trúc output"""
    if isinstance(obj, dict):
        for key, value in obj.items():
            if isinstance(value, dict):
                print(f"{indent}{key}:")
                print_output_structure(value, indent + '  ')
            elif isinstance(value, list):
                print(f"{indent}{key}: [list, {len(value)} items]")
                if len(value) > 0 and isinstance(value[0], dict):
                    print(f"{indent}  First item:")
                    print_output_structure(value[0], indent + '    ')
            else:
                print(f"{indent}{key}: {value}")
    elif isinstance(value, list):
        print(f"{indent}[list, {len(obj)} items]")



