//
//  RtmpManager.m
//  LiveKit
//
//  Created by ptssg on 2017/11/2.
//  Copyright © 2017年 PT. All rights reserved.
//

#import "RtmpManager.h"
#import "rtmp.h"

#define RTMP_HEAD_SIZE (sizeof(RTMPPacket)+RTMP_MAX_HEADER_SIZE)

@interface RtmpManager () {
    RTMP *rtmp;
    double startTimeStamp;
}
@end

@implementation RtmpManager

- (BOOL)rtmpConnect:(NSString *)url {
    if (rtmp) {
        [self rtmpClose];
    }
    
    rtmp = RTMP_Alloc();
    RTMP_Init(rtmp);
    
    if (RTMP_SetupURL(rtmp, (char *)[url cStringUsingEncoding:NSUTF8StringEncoding]) < 0) {
        RTMP_Free(rtmp);
        return false;
    }
    
    RTMP_EnableWrite(rtmp);
    
    if (RTMP_Connect(rtmp, NULL) < 0) {
        RTMP_Free(rtmp);
        return false;
    }
    
    if (RTMP_ConnectStream(rtmp, 0) < 0) {
        RTMP_Close(rtmp);
        RTMP_Free(rtmp);
        return false;
    }
    
    startTimeStamp = [[NSDate date] timeIntervalSince1970]*1000;
    
    return true;
}

- (void)rtmpClose {
    if (rtmp) {
        RTMP_Close(rtmp);
        RTMP_Free(rtmp);
        rtmp = NULL;
    }
}

- (void)sendAVCCSps:(NSData *)sps
                Pps:(NSData *)pps {
    if (rtmp != NULL) {
        
        int i = 0;
        unsigned char *spsData = (unsigned char *)sps.bytes;
        unsigned char *ppsData = (unsigned char *)pps.bytes;
        int spslen = (int)sps.length;
        int ppslen = (int)pps.length;
        
        RTMPPacket *packet;
        unsigned char *body;
        
        packet = (RTMPPacket *)malloc(RTMP_HEAD_SIZE+1024);
        memset(packet,0,RTMP_HEAD_SIZE);
        
        packet->m_body = (char *)packet + RTMP_HEAD_SIZE;
        body = (unsigned char *)packet->m_body;
        
        body[i++] = 0x17;
        body[i++] = 0x00;
        
        body[i++] = 0x00;
        body[i++] = 0x00;
        body[i++] = 0x00;
        
        body[i++] = 0x01;
        body[i++] = spsData[1];
        body[i++] = spsData[2];
        body[i++] = spsData[3];
        body[i++] = 0xff;
        
        body[i++] = 0xe1;
        body[i++] = (spslen >> 8) & 0xff;
        body[i++] = spslen & 0xff;
        memcpy(&body[i], spsData, spslen);
        i += spslen;
        
        body[i++] = 0x01;
        body[i++] = (ppslen >> 8) & 0xff;
        body[i++] = ppslen & 0xff;
        memcpy(&body[i], ppsData, ppslen);
        i += ppslen;
        
        packet->m_packetType = RTMP_PACKET_TYPE_VIDEO;
        packet->m_nBodySize = i;
        packet->m_nChannel = 0x04;
        packet->m_nTimeStamp = 0;
        packet->m_hasAbsTimestamp = 0;
        packet->m_headerType = RTMP_PACKET_SIZE_LARGE;
        packet->m_nInfoField2 = rtmp->m_stream_id;
        
        if (RTMP_IsConnected(rtmp)) {
            if (RTMP_SendPacket(rtmp, packet, true) != 1) {
                NSLog(@"error");
            }
        }
        free(packet);
    }
}

- (void)sendAVCFrame:(NSData *)frame
          isKeyFrame:(BOOL)isKeyFrame {
    if (rtmp != NULL) {
        
        RTMPPacket *packet;
        unsigned char *body;
        
        unsigned char *data = (unsigned char *)frame.bytes;
        int data_len = (int)frame.length;
        uint32_t timeStamp = [[NSDate date]timeIntervalSince1970]*1000 - startTimeStamp;
        
        packet = (RTMPPacket *)malloc(RTMP_HEAD_SIZE + data_len + 9);
        memset(packet,0,RTMP_HEAD_SIZE);
        
        packet->m_body = (char *)packet + RTMP_HEAD_SIZE;
        packet->m_nBodySize = data_len + 9;
        
        body = (unsigned char *)packet->m_body;
        memset(body,0,data_len + 9);
        
        if (isKeyFrame) {
            body[0] = 0x17;
        }else {
            body[0] = 0x27;
        }
        
        body[1] = 0x01;
        
        body[2] = 0x00;
        body[3] = 0x00;
        body[4] = 0x00;
        
        body[5] = (data_len >> 24) & 0xff;
        body[6] = (data_len >> 16) & 0xff;
        body[7] = (data_len >> 8) & 0xff;
        body[8] = data_len & 0xff;
        
        memcpy(&body[9], data, data_len);
        
        packet->m_packetType = RTMP_PACKET_TYPE_VIDEO;
        packet->m_nChannel = 0x04;
        packet->m_nTimeStamp = timeStamp;
        packet->m_hasAbsTimestamp = 0;
        packet->m_headerType = RTMP_PACKET_SIZE_LARGE;
        packet->m_nInfoField2 = rtmp->m_stream_id;
        
        if (RTMP_IsConnected(rtmp)) {
            if (RTMP_SendPacket(rtmp, packet, true) != 1) {
                NSLog(@"error");
            }
        }
        free(packet);
    }
}

- (void)sendAACSpec:(NSData *)spec {
    if (rtmp != NULL) {
        
        RTMPPacket *packet;
        unsigned char *body;
        
        unsigned char *specData = (unsigned char *)spec.bytes;
        int speclen = (int)spec.length;
        
        packet = (RTMPPacket *)malloc(RTMP_HEAD_SIZE+speclen+2);
        memset(packet, 0, RTMP_HEAD_SIZE);
        
        packet->m_body = (char *)packet + RTMP_HEAD_SIZE;
        body = (unsigned char *)packet->m_body;
        
        body[0] = 0xAF;
        body[1] = 0x00;
        memcpy(&body[2], specData, speclen);
        
        packet->m_packetType = RTMP_PACKET_TYPE_AUDIO;
        packet->m_nBodySize = speclen+2;
        packet->m_nChannel = 0x04;
        packet->m_nTimeStamp = 0;
        packet->m_hasAbsTimestamp = 0;
        packet->m_headerType = RTMP_PACKET_SIZE_LARGE;
        packet->m_nInfoField2 = rtmp->m_stream_id;
        
        if (RTMP_IsConnected(rtmp)) {
            if (RTMP_SendPacket(rtmp, packet, true) != 1) {
                NSLog(@"error");
            }
        }
        free(packet);
    }
}

- (void)sendAACFrame:(NSData *)frame {
    if (rtmp != NULL) {
        
        unsigned char *data = (unsigned char *)frame.bytes;
        int datalen = (int)frame.length;
        uint32_t timeStamp = [[NSDate date]timeIntervalSince1970]*1000 - startTimeStamp;
        
        RTMPPacket *packet;
        unsigned char *body;
        
        packet = (RTMPPacket *)malloc(RTMP_HEAD_SIZE+datalen+2);
        memset(packet, 0, RTMP_HEAD_SIZE);
        
        packet->m_body = (char *)packet + RTMP_HEAD_SIZE;
        body = (unsigned char *)packet->m_body;
        
        body[0] = 0xAF;
        body[1] = 0x01;
        memcpy(&body[2], data, datalen);
        
        packet->m_packetType = RTMP_PACKET_TYPE_AUDIO;
        packet->m_nBodySize = datalen+2;
        packet->m_nChannel = 0x04;
        packet->m_nTimeStamp = timeStamp;
        packet->m_hasAbsTimestamp = 0;
        packet->m_headerType = RTMP_PACKET_SIZE_LARGE;
        packet->m_nInfoField2 = rtmp->m_stream_id;
        
        if (RTMP_IsConnected(rtmp)) {
            if (RTMP_SendPacket(rtmp, packet, true) != 1) {
                NSLog(@"error");
            }
        }
        free(packet);
    }
}

@end
